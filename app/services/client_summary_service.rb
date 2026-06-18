class ClientSummaryService
  CACHE_KEY_PREFIX = "client_summary"

  class << self
    def generate(client_id)
      Observability.with_span("generate_client_summary", attributes: {
        "client.id" => client_id
      }) do
        key    = "#{CACHE_KEY_PREFIX}:#{client_id}"
        cached = SummaryCacheService.fetch(key)
        if cached
          Observability.add_attributes({
            "summary.source" => "cache",
            "summary.exists" => true
          })
          return cached
        end

        client = Client.find(client_id)
        Observability.add_attributes(client_attributes(client))

        if (existing = client.client_summary)
          plaintext = EncryptionService.decrypt(existing.summary_encrypted)
          result = {
            actors:                existing.actors,
            concluded_discussions: existing.concluded_discussions,
            open_action_items:     existing.open_action_items,
            summary:               plaintext
          }
          SummaryCacheService.write(key, result)
          Observability.add_attributes({
            "summary.source" => "database",
            "summary.exists" => true
          })
          return result
        end

        threads = Observability.with_span("load_threads", attributes: client_attributes(client)) do
          MockEmailService.fetch_client_threads(client).to_a
        end

        thread_summaries = Observability.with_span("load_thread_summaries", attributes: client_attributes(client).merge("threads.count" => threads.count)) do
          threads.map do |thread|
            SummaryService.generate(thread.conversation_id, preloaded_thread: thread)
          end
        end

        total_emails = threads.sum { |thread| thread.email_messages.size }
        Observability.add_attributes({
          "threads.count" => threads.count,
          "emails.count" => total_emails,
          "summary.source" => "generated",
          "summary.exists" => false
        })

        raise GeminiClient::RequestInProgressError unless SummaryCacheService.lock(key)
        begin
          summaries_text = Observability.with_span("aggregate_summary", attributes: client_attributes(client).merge("threads.count" => threads.count, "emails.count" => total_emails)) do
            build_summaries_text(threads, thread_summaries)
          end
          gemini_result = Observability.with_span("llm_summarization_call", attributes: client_attributes(client).merge(
            "threads.count" => threads.count,
            "emails.count" => total_emails,
            "llm.operation" => "client_summary"
          )) do
            GeminiClient.generate_client_summary(summaries_text)
          end
          encrypted = EncryptionService.encrypt(gemini_result[:summary])

          Observability.with_span("persist_client_summary", attributes: client_attributes(client).merge("threads.count" => threads.count, "emails.count" => total_emails)) do
            ClientSummary.create!(
              client:                 client,
              summary_encrypted:      encrypted,
              actors:                 gemini_result[:actors],
              concluded_discussions:  gemini_result[:concluded_discussions],
              open_action_items:      gemini_result[:open_action_items],
              emails_analyzed_count:  total_emails,
              threads_analyzed_count: threads.count,
              last_refreshed_at:      Time.current
            )
          end

          SummaryCacheService.write(key, gemini_result)
          Observability.increment_counter("client_summary_generation_total", attributes: {
            "firm.id" => client.firm_id
          })
          Observability.log_info("Client summary generated", attributes: client_attributes(client).merge(
            "threads.count" => threads.count,
            "emails.count" => total_emails
          ))
          gemini_result
        ensure
          SummaryCacheService.unlock(key)
        end
      end
    end

    private

    def client_attributes(client)
      {
        "client.id" => client.id,
        "client.email" => client.email,
        "client.name" => client.name,
        "firm.id" => client.firm_id
      }
    end

    def build_summaries_text(threads, summaries)
      threads.zip(summaries).map do |thread, summary|
        <<~TEXT
          Thread: #{thread.subject}
          Summary: #{summary[:summary]}
          Actors: #{Array(summary[:actors]).join(", ")}
          Concluded: #{Array(summary[:concluded_discussions]).join("; ")}
          Open: #{Array(summary[:open_action_items]).join("; ")}
        TEXT
      end.join("\n---\n\n")
    end
  end
end
