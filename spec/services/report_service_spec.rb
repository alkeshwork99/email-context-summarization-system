require "rails_helper"

describe ReportService do
  let(:abc_firm) { create(:firm, name: "ABC CPA") }
  let(:xyz_firm) { create(:firm, name: "XYZ CPA") }
  let(:admin)    { create(:accountant, :admin, firm: abc_firm) }

  let(:alice)   { create(:client, firm: abc_firm) }
  let(:bob)     { create(:client, firm: abc_firm) }
  let(:charlie) { create(:client, firm: xyz_firm) }

  before do
    create(:client_summary, client: alice)
    create(:client_summary, client: bob)
    create(:client_summary, client: charlie)
  end

  describe ".firm_summary_report", :observability do
    it "returns the firm name and correct client count" do
      result = ReportService.firm_summary_report(admin)
      expect(result[:firm_name]).to eq("ABC CPA")
      expect(result[:total_clients_with_summaries]).to eq(2)
    end

    it "excludes clients from other firms" do
      xyz_admin = create(:accountant, :admin, firm: xyz_firm)
      result = ReportService.firm_summary_report(xyz_admin)
      expect(result[:total_clients_with_summaries]).to eq(1)
    end

    it "increments the firm report counter with the correct attribute" do
      ReportService.firm_summary_report(admin)

      span = span_named("firm_summary_report")
      expect(span.attributes).to include(
        "report.type" => "firm",
        "firm.id" => admin.firm_id,
        "firm.name" => "ABC CPA",
        "report.result_count" => 2
      )
      expect(Observability.counter_value("report_generation_total", attributes: { "report.type" => "firm" })).to eq(1)
    end
  end

  describe ".global_summary_report", :observability do
    it "includes all firms with at least one client summary" do
      names = ReportService.global_summary_report.map { |r| r[:firm_name] }
      expect(names).to include("ABC CPA", "XYZ CPA")
    end

    it "returns correct counts per firm" do
      result = ReportService.global_summary_report
      abc = result.find { |r| r[:firm_name] == "ABC CPA" }
      xyz = result.find { |r| r[:firm_name] == "XYZ CPA" }
      expect(abc[:total_clients_with_summaries]).to eq(2)
      expect(xyz[:total_clients_with_summaries]).to eq(1)
    end

    it "increments the global report counter with the correct attribute" do
      ReportService.global_summary_report

      span = span_named("global_summary_report")
      expect(span.attributes).to include(
        "report.type" => "global",
        "report.result_count" => 2
      )
      expect(Observability.counter_value("report_generation_total", attributes: { "report.type" => "global" })).to eq(1)
    end
  end
end
