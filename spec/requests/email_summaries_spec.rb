require "rails_helper"

describe "EmailSummaries endpoints" do
  let(:firm)         { create(:firm) }
  let(:accountant)   { create(:accountant, firm: firm) }
  let(:token)        { JwtService.encode(accountant.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }
  let(:client)             { create(:client, firm: firm) }
  let!(:thread)            { create(:email_thread, client: client, conversation_id: "conv_001") }
  let!(:accountant_message) { create(:email_message, email_thread: thread, accountant: accountant) }

  let(:stub_result) do
    {
      actors:                [ "Alice", "Bob" ],
      concluded_discussions: [ "Filed taxes" ],
      open_action_items:     [ "Submit W2" ],
      summary:               "Alice and Bob discussed tax filings."
    }
  end

  before do
    allow(SummaryService).to receive(:generate).and_return(stub_result)
    allow(SummaryRefreshService).to receive(:refresh).and_return(stub_result)
  end

  describe "GET /email_summaries/:conversation_id" do
    context "without a token" do
      it "returns 401" do
        get "/email_summaries/conv_001"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a bad token" do
      it "returns 401" do
        get "/email_summaries/conv_001", headers: { "Authorization" => "Bearer badtoken" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid token" do
      it "returns 200 with correct actors and summary" do
        get "/email_summaries/conv_001", headers: auth_headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["actors"]).to eq([ "Alice", "Bob" ])
        expect(body["summary"]).to eq("Alice and Bob discussed tax filings.")
        expect(body["concluded_discussions"]).to eq([ "Filed taxes" ])
        expect(body["open_action_items"]).to eq([ "Submit W2" ])
      end

      it "adds request attributes to the current span", :observability do
        Observability.with_span("request") do
          get "/email_summaries/conv_001", headers: auth_headers
        end

        request_span = span_named("request")
        expect(request_span.attributes).to include(
          "http.route" => "/email_summaries/conv_001",
          "accountant.id" => accountant.id,
          "accountant.role" => accountant.role,
          "firm.id" => firm.id,
          "thread.conversation_id" => "conv_001"
        )
      end
    end

    context "when the conversation does not exist" do
      before do
        allow(SummaryService).to receive(:generate).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns 404" do
        get "/email_summaries/conv_999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when Gemini is rate limited" do
      before do
        allow(SummaryService).to receive(:generate).and_raise(GeminiClient::RateLimitError)
      end

      it "returns 503" do
        get "/email_summaries/conv_001", headers: auth_headers
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq("AI quota exceeded — try again later")
      end
    end

    context "when a summary generation is already in progress" do
      before do
        allow(SummaryService).to receive(:generate).and_raise(GeminiClient::RequestInProgressError)
      end

      it "returns 503 with an in-progress message" do
        get "/email_summaries/conv_001", headers: auth_headers
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to include("already being generated")
      end
    end

    context "when the conversation belongs to a different firm" do
      let(:other_firm)    { create(:firm) }
      let(:other_client)  { create(:client, firm: other_firm) }
      let!(:other_thread) { create(:email_thread, client: other_client, conversation_id: "conv_other") }

      it "returns 404" do
        get "/email_summaries/conv_other", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when accountant has no messages in the conversation" do
      let(:silent_client) { create(:client, firm: firm) }
      let!(:silent_thread) { create(:email_thread, client: silent_client, conversation_id: "conv_silent") }

      it "returns 404" do
        get "/email_summaries/conv_silent", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the requester is a superuser" do
      let(:superuser)     { create(:accountant, :superuser, firm: firm) }
      let(:super_token)   { JwtService.encode(superuser.id) }
      let(:super_headers) { { "Authorization" => "Bearer #{super_token}" } }
      let(:other_firm)    { create(:firm) }
      let(:other_client)  { create(:client, firm: other_firm) }
      let!(:other_thread) { create(:email_thread, client: other_client, conversation_id: "conv_super") }

      it "can access a thread from a different firm" do
        get "/email_summaries/conv_super", headers: super_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /email_summaries/:conversation_id/refresh" do
    context "with a valid token" do
      it "returns 200 with correct actors and summary" do
        post "/email_summaries/conv_001/refresh", headers: auth_headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["actors"]).to eq([ "Alice", "Bob" ])
        expect(body["summary"]).to eq("Alice and Bob discussed tax filings.")
      end
    end

    context "without a token" do
      it "returns 401" do
        post "/email_summaries/conv_001/refresh"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
