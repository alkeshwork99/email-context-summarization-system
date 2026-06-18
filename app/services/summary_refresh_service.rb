class SummaryRefreshService
  class << self
    def refresh(conversation_id)
      thread = MockEmailService.fetch_thread(conversation_id)

      Observability.with_span("refresh_email_summary", attributes: refresh_attributes(thread)) do
        Observability.with_span("delete_existing_summary") do
          SummaryCacheService.delete("summary:#{conversation_id}")
          SummaryCacheService.delete("client_summary:#{thread.client_id}")
          thread.email_summary&.destroy!
          thread.client.client_summary&.destroy!
        end

        result = Observability.with_span("regenerate_summary") do
          SummaryService.generate(conversation_id)
        end

        Observability.increment_counter("email_summary_refresh_total", attributes: {
          "firm.id" => thread.client.firm_id
        })
        Observability.log_info("Email summary refreshed", attributes: refresh_attributes(thread))
        result
      end
    end

    private

    def refresh_attributes(thread)
      {
        "thread.conversation_id" => thread.conversation_id,
        "thread.id" => thread.id,
        "client.id" => thread.client_id,
        "firm.id" => thread.client.firm_id
      }
    end
  end
end
