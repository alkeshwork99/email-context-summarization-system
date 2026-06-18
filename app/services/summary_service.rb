class SummaryService
  class << self
    def generate(conversation_id, preloaded_thread: nil)
      Observability.with_span("generate_email_summary", attributes: {
        "thread.conversation_id" => conversation_id
      }) do
        key    = "summary:#{conversation_id}"
        cached = SummaryCacheService.fetch(key)

        if cached
          Observability.add_attributes({
            "summary.source" => "cache",
            "summary.exists" => true
          })
          return cached
        end

        thread = preloaded_thread || MockEmailService.fetch_thread(conversation_id)
        Observability.add_attributes(root_thread_attributes(thread))

        if (email_summary = thread.email_summary)
          plaintext = EncryptionService.decrypt(email_summary.summary_encrypted)
          result = {
            actors:                email_summary.actors,
            concluded_discussions: email_summary.concluded_discussions,
            open_action_items:     email_summary.open_action_items,
            summary:               plaintext
          }
          SummaryCacheService.write(key, result)
          Observability.add_attributes({
            "summary.source" => "database",
            "summary.exists" => true
          })
          return result
        end

        raise GeminiClient::RequestInProgressError unless SummaryCacheService.lock(key)
        begin
          messages = Observability.with_span("load_messages", attributes: thread_attributes(thread)) do
            MockEmailService.fetch_messages(thread)
          end
          Observability.add_attributes({
            "emails.count" => messages.count,
            "summary.source" => "generated",
            "summary.exists" => false
          })
          gemini_result = Observability.with_span("llm_summarization_call", attributes: llm_attributes(thread, messages.count, "thread_summary")) do
            GeminiClient.generate_summary(build_thread_text(messages))
          end
          encrypted = EncryptionService.encrypt(gemini_result[:summary])

          Observability.with_span("save_email_summary", attributes: thread_attributes(thread).merge("emails.count" => messages.count)) do
            EmailSummary.create!(
              email_thread:          thread,
              summary_encrypted:     encrypted,
              actors:                gemini_result[:actors],
              concluded_discussions: gemini_result[:concluded_discussions],
              open_action_items:     gemini_result[:open_action_items],
              emails_analyzed_count: messages.count,
              last_refreshed_at:     Time.current
            )
          end

          SummaryCacheService.write(key, gemini_result)
          Observability.increment_counter("email_summary_generation_total", attributes: counter_attributes(thread))
          Observability.log_info("Email summary generated", attributes: thread_attributes(thread).merge("emails.count" => messages.count))
          gemini_result
        ensure
          SummaryCacheService.unlock(key)
        end
      end
    end

    private

    def thread_attributes(thread)
      {
        "thread.conversation_id" => thread.conversation_id,
        "thread.id" => thread.id,
        "thread.subject" => thread.subject,
        "client.id" => thread.client_id,
        "client.email" => thread.client.email,
        "firm.id" => thread.client.firm_id
      }
    end

    def root_thread_attributes(thread)
      {
        "thread.conversation_id" => thread.conversation_id,
        "thread.id" => thread.id,
        "client.id" => thread.client_id,
        "firm.id" => thread.client.firm_id
      }
    end

    def llm_attributes(thread, email_count, operation)
      thread_attributes(thread).merge(
        "emails.count" => email_count,
        "llm.operation" => operation
      )
    end

    def counter_attributes(thread)
      {
        "firm.id" => thread.client.firm_id
      }
    end

    def build_thread_text(messages)
      messages.map { |msg| "#{msg.from_email}:\n#{msg.body}" }.join("\n\n")
    end
  end
end
