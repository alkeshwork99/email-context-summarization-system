require "rails_helper"

describe "Reports endpoints" do
  let(:firm)       { create(:firm, name: "Test CPA") }
  let(:admin)      { create(:accountant, :admin,     firm: firm) }
  let(:superuser)  { create(:accountant, :superuser, firm: firm) }
  let(:accountant) { create(:accountant,             firm: firm) }

  let(:admin_headers)     { { "Authorization" => "Bearer #{JwtService.encode(admin.id)}" } }
  let(:superuser_headers) { { "Authorization" => "Bearer #{JwtService.encode(superuser.id)}" } }
  let(:acct_headers)      { { "Authorization" => "Bearer #{JwtService.encode(accountant.id)}" } }

  before do
    2.times do
      client = create(:client, firm: firm)
      create(:client_summary, client: client)
    end
  end

  describe "GET /reports/firm" do
    context "as admin" do
      it "returns 200 with the correct firm name and client count" do
        get "/reports/firm", headers: admin_headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["firm_name"]).to eq("Test CPA")
        expect(body["total_clients_with_summaries"]).to eq(2)
      end

      it "adds report request attributes to the current span", :observability do
        Observability.with_span("request") do
          get "/reports/firm", headers: admin_headers
        end

        request_span = span_named("request")
        expect(request_span.attributes).to include(
          "http.route" => "/reports/firm",
          "accountant.id" => admin.id,
          "accountant.role" => admin.role,
          "firm.id" => firm.id,
          "report.type" => "firm"
        )
      end
    end

    context "as regular accountant" do
      it "returns 403 with Forbidden error" do
        get "/reports/firm", headers: acct_headers
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["error"]).to eq("Forbidden")
      end
    end

    context "as superuser" do
      it "returns 403" do
        get "/reports/firm", headers: superuser_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without a token" do
      it "returns 401" do
        get "/reports/firm"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /reports/global" do
    context "as superuser" do
      it "returns 200 with an array containing the firm and its count" do
        get "/reports/global", headers: superuser_headers
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result).to be_an(Array)
        firm_entry = result.find { |r| r["firm_name"] == "Test CPA" }
        expect(firm_entry["total_clients_with_summaries"]).to eq(2)
      end
    end

    context "as admin" do
      it "returns 403 with Forbidden error" do
        get "/reports/global", headers: admin_headers
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["error"]).to eq("Forbidden")
      end
    end

    context "as regular accountant" do
      it "returns 403" do
        get "/reports/global", headers: acct_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without a token" do
      it "returns 401" do
        get "/reports/global"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
