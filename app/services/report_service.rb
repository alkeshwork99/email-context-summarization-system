class ReportService
  class << self
    def firm_summary_report(accountant)
      Observability.with_span("firm_summary_report", attributes: {
        "report.type" => "firm",
        "firm.id" => accountant.firm_id,
        "firm.name" => accountant.firm.name
      }) do
        count = Client
          .joins(:client_summary)
          .where(firm_id: accountant.firm_id)
          .count

        Observability.add_attributes({ "report.result_count" => count })
        Observability.increment_counter("report_generation_total", attributes: {
          "report.type" => "firm"
        })
        Observability.log_info("Report generated", attributes: {
          "report.type" => "firm",
          "firm.id" => accountant.firm_id,
          "firm.name" => accountant.firm.name,
          "report.result_count" => count
        })

        { firm_name: accountant.firm.name, total_clients_with_summaries: count }
      end
    end

    def global_summary_report
      Observability.with_span("global_summary_report", attributes: {
        "report.type" => "global"
      }) do
        result = Firm
          .joins(clients: :client_summary)
          .select("firms.name AS firm_name, COUNT(DISTINCT clients.id) AS total_clients_with_summaries")
          .group("firms.id, firms.name")
          .map { |row| { firm_name: row.firm_name, total_clients_with_summaries: row.total_clients_with_summaries.to_i } }

        Observability.add_attributes({ "report.result_count" => result.count })
        Observability.increment_counter("report_generation_total", attributes: {
          "report.type" => "global"
        })
        Observability.log_info("Report generated", attributes: {
          "report.type" => "global",
          "report.result_count" => result.count
        })

        result
      end
    end
  end
end
