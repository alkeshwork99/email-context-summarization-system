require "rails_helper"

describe "ClientSummaries endpoints" do
  let(:firm)         { create(:firm) }
  let(:accountant)   { create(:accountant, firm: firm) }
  let(:token)        { JwtService.encode(accountant.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }
  let(:client)            { create(:client, firm: firm) }
  let!(:client_thread)    { create(:email_thread, client: client) }
  let!(:accountant_message) { create(:email_message, email_thread: client_thread, accountant: accountant) }

  let(:stub_result) do
    {
      actors:                [ "Alice Brown", "John Smith", "Mary Johnson" ],
      concluded_discussions: [ "W-2 documents received" ],
      open_action_items:     [ "Submit 1099-NEC forms" ],
      summary:               "Alice has W-2 resolved but 1099-NEC is still outstanding."
    }
  end

  before do
    allow(ClientSummaryService).to receive(:generate).and_return(stub_result)
    allow(ClientSummaryRefreshService).to receive(:refresh).and_return(stub_result)
  end

  describe "GET /client_summaries/:client_id" do
    context "without a token" do
      it "returns 401" do
        get "/client_summaries/#{client.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a bad token" do
      it "returns 401" do
        get "/client_summaries/#{client.id}", headers: { "Authorization" => "Bearer badtoken" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid token" do
      it "returns 200 with the full summary shape" do
        get "/client_summaries/#{client.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["summary"]).to eq(stub_result[:summary])
        expect(body["actors"]).to eq(stub_result[:actors])
        expect(body["concluded_discussions"]).to eq(stub_result[:concluded_discussions])
        expect(body["open_action_items"]).to eq(stub_result[:open_action_items])
      end

      it "adds request attributes to the current span", :observability do
        Observability.with_span("request") do
          get "/client_summaries/#{client.id}", headers: auth_headers
        end

        request_span = span_named("request")
        expect(request_span.attributes).to include(
          "http.route" => "/client_summaries/#{client.id}",
          "accountant.id" => accountant.id,
          "accountant.role" => accountant.role,
          "firm.id" => firm.id,
          "client.id" => client.id,
          "client.email" => client.email,
          "client.name" => client.name
        )
      end
    end

    context "when the client does not exist" do
      before do
        allow(ClientSummaryService).to receive(:generate).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns 404" do
        get "/client_summaries/00000000-0000-0000-0000-000000000000", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when Gemini is rate limited" do
      before do
        allow(ClientSummaryService).to receive(:generate).and_raise(GeminiClient::RateLimitError)
      end

      it "returns 503" do
        get "/client_summaries/#{client.id}", headers: auth_headers
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq("AI quota exceeded — try again later")
      end
    end

    context "when a client summary generation is already in progress" do
      before do
        allow(ClientSummaryService).to receive(:generate).and_raise(GeminiClient::RequestInProgressError)
      end

      it "returns 503 with an in-progress message" do
        get "/client_summaries/#{client.id}", headers: auth_headers
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to include("already being generated")
      end
    end

    context "when the client belongs to a different firm" do
      let(:other_firm)   { create(:firm) }
      let(:other_client) { create(:client, firm: other_firm) }

      it "returns 404" do
        get "/client_summaries/#{other_client.id}", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when accountant has no messages for the client" do
      let(:silent_client) { create(:client, firm: firm) }

      it "returns 404" do
        get "/client_summaries/#{silent_client.id}", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the requester is a superuser" do
      let(:superuser)     { create(:accountant, :superuser, firm: firm) }
      let(:super_token)   { JwtService.encode(superuser.id) }
      let(:super_headers) { { "Authorization" => "Bearer #{super_token}" } }
      let(:other_firm)    { create(:firm) }
      let(:other_client)  { create(:client, firm: other_firm) }

      it "can access a client from a different firm" do
        get "/client_summaries/#{other_client.id}", headers: super_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /client_summaries/:client_id/refresh" do
    context "without a token" do
      it "returns 401" do
        post "/client_summaries/#{client.id}/refresh"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid token" do
      it "returns 200 with the refreshed summary" do
        post "/client_summaries/#{client.id}/refresh", headers: auth_headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["summary"]).to eq(stub_result[:summary])
        expect(body["actors"]).to eq(stub_result[:actors])
      end
    end
  end
end
