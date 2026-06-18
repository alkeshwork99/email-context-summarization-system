class ClientSummaryRefreshService
  class << self
    def refresh(client_id)
      client = Client.find(client_id)

      Observability.with_span("refresh_client_summary", attributes: refresh_attributes(client)) do
        Observability.with_span("delete_existing_summary", attributes: refresh_attributes(client)) do
          SummaryCacheService.delete("client_summary:#{client_id}")
          client.client_summary&.destroy!
        end

        result = Observability.with_span("regenerate_summary", attributes: refresh_attributes(client)) do
          ClientSummaryService.generate(client_id)
        end

        Observability.increment_counter("client_summary_refresh_total", attributes: {
          "firm.id" => client.firm_id
        })
        Observability.log_info("Client summary refreshed", attributes: refresh_attributes(client))
        result
      end
    end

    private

    def refresh_attributes(client)
      {
        "client.id" => client.id,
        "client.email" => client.email,
        "client.name" => client.name,
        "firm.id" => client.firm_id
      }
    end
  end
end
