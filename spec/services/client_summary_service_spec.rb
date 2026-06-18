require "rails_helper"

describe ClientSummaryService do
  let(:redis)  { instance_double(Redis) }
  let(:client) { create(:client) }

  let(:gemini_result) do
    {
      actors:                [ "Alice Brown", "John Smith", "Mary Johnson" ],
      concluded_discussions: [ "W-2 documents received" ],
      open_action_items:     [ "Submit 1099-NEC forms" ],
      summary:               "Alice has resolved her W-2 but still needs to submit 1099-NEC forms."
    }
  end

  let(:cache_key) { "client_summary:#{client.id}" }

  before { allow(Redis).to receive(:new).and_return(redis) }

  describe ".generate" do
    context "when result is cached in Redis" do
      it "returns the cached result without touching the database or Gemini" do
        allow(redis).to receive(:get).with(cache_key).and_return(JSON.generate(gemini_result))

        expect(MockEmailService).not_to receive(:fetch_client_threads)
        expect(GeminiClient).not_to receive(:generate_client_summary)

        result = ClientSummaryService.generate(client.id.to_s)
        expect(result[:summary]).to eq(gemini_result[:summary])
      end
    end

    context "when result is in the database but not Redis" do
      it "decrypts and re-caches without calling Gemini" do
        create(:client_summary, client: client)
        allow(redis).to receive(:get).with(cache_key).and_return(nil)
        allow(redis).to receive(:set)

        expect(GeminiClient).not_to receive(:generate_client_summary)

        result = ClientSummaryService.generate(client.id.to_s)
        expect(result[:summary]).to eq("Test client summary")
      end
    end

    context "when no result exists anywhere", :observability do
      let(:thread1) { create(:email_thread, client: client) }
      let(:thread2) { create(:email_thread, client: client) }
      let(:thread_summary) do
        {
          actors:                [ "Alice Brown", "John Smith" ],
          concluded_discussions: [ "W-2 received" ],
          open_action_items:     [],
          summary:               "Thread resolved."
        }
      end

      before do
        create(:email_message, email_thread: thread1)
        create(:email_message, email_thread: thread2)
        allow(redis).to receive(:get).and_return(nil)
        allow(redis).to receive(:set)
        allow(SummaryService).to receive(:generate).and_return(thread_summary)
        allow(GeminiClient).to receive(:generate_client_summary).and_return(gemini_result)
        allow(SummaryCacheService).to receive(:lock).and_return("OK")
        allow(SummaryCacheService).to receive(:unlock)
      end

      it "calls SummaryService for each thread then calls GeminiClient.generate_client_summary" do
        expect(SummaryService).to receive(:generate).twice
        expect(GeminiClient).to receive(:generate_client_summary)
        ClientSummaryService.generate(client.id.to_s)
      end

      it "creates a ClientSummary record" do
        expect {
          ClientSummaryService.generate(client.id.to_s)
        }.to change(ClientSummary, :count).by(1)
      end

      it "stores emails_analyzed_count and threads_analyzed_count" do
        ClientSummaryService.generate(client.id.to_s)
        summary = client.reload.client_summary
        expect(summary.threads_analyzed_count).to eq(2)
        expect(summary.emails_analyzed_count).to eq(2)
      end

      it "writes the result to Redis" do
        expect(redis).to receive(:set).with(cache_key, anything)
        ClientSummaryService.generate(client.id.to_s)
      end

      it "returns the Gemini result" do
        result = ClientSummaryService.generate(client.id.to_s)
        expect(result[:summary]).to eq(gemini_result[:summary])
        expect(result[:actors]).to eq(gemini_result[:actors])
      end

      it "emits spans, resource attributes, and the generation counter" do
        ClientSummaryService.generate(client.id.to_s)

        root_span = span_named("generate_client_summary")
        expect(root_span.attributes).to include(
          "client.id" => client.id,
          "client.email" => client.email,
          "client.name" => client.name,
          "firm.id" => client.firm_id,
          "threads.count" => 2,
          "emails.count" => 2,
          "summary.source" => "generated",
          "summary.exists" => false
        )
        expect(span_named("load_threads").attributes["client.id"]).to eq(client.id)
        expect(span_named("load_thread_summaries").attributes["threads.count"]).to eq(2)
        expect(span_named("aggregate_summary").attributes["emails.count"]).to eq(2)
        expect(span_named("persist_client_summary").attributes["threads.count"]).to eq(2)
        expect(span_named("llm_summarization_call").attributes["llm.operation"]).to eq("client_summary")
        expect(Observability.counter_value("client_summary_generation_total", attributes: { "firm.id" => client.firm_id.to_s })).to eq(1)
      end
    end

    context "when client has a single thread" do
      let(:single_thread_client) { create(:client) }

      before do
        thread = create(:email_thread, client: single_thread_client)
        create(:email_message, email_thread: thread)
        allow(redis).to receive(:get).and_return(nil)
        allow(redis).to receive(:set)
        allow(SummaryService).to receive(:generate).and_return(gemini_result)
        allow(GeminiClient).to receive(:generate_client_summary).and_return(gemini_result)
        allow(SummaryCacheService).to receive(:lock).and_return("OK")
        allow(SummaryCacheService).to receive(:unlock)
      end

      it "generates a client summary from a single thread" do
        expect {
          ClientSummaryService.generate(single_thread_client.id.to_s)
        }.to change(ClientSummary, :count).by(1)
      end
    end

    context "when client has no threads" do
      let(:empty_client) { create(:client) }

      before do
        allow(redis).to receive(:get).and_return(nil)
        allow(redis).to receive(:set)
        allow(GeminiClient).to receive(:generate_client_summary).and_return(gemini_result)
        allow(SummaryCacheService).to receive(:lock).and_return("OK")
        allow(SummaryCacheService).to receive(:unlock)
      end

      it "calls Gemini with empty thread summaries and creates a record" do
        expect {
          ClientSummaryService.generate(empty_client.id.to_s)
        }.to change(ClientSummary, :count).by(1)
      end
    end

    context "when client_id is invalid" do
      before { allow(redis).to receive(:get).and_return(nil) }

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          ClientSummaryService.generate("00000000-0000-0000-0000-000000000000")
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when a Gemini call is already in progress for the same client" do
      let(:locked_client) { create(:client) }

      before do
        create(:email_thread, client: locked_client)
        allow(redis).to receive(:get).and_return(nil)
        allow(SummaryCacheService).to receive(:lock).and_return(nil)
        allow(SummaryService).to receive(:generate).and_return(gemini_result)
      end

      it "raises GeminiClient::RequestInProgressError without calling Gemini" do
        expect(GeminiClient).not_to receive(:generate_client_summary)
        expect {
          ClientSummaryService.generate(locked_client.id.to_s)
        }.to raise_error(GeminiClient::RequestInProgressError)
      end
    end

    context "when a second accountant at the same firm requests a client summary already generated by another accountant" do
      let(:firm)          { create(:firm) }
      let(:alice)         { create(:accountant, firm: firm) }
      let(:bob)           { create(:accountant, firm: firm) }
      let(:shared_client) { create(:client, firm: firm) }
      let(:shared_key)    { "client_summary:#{shared_client.id}" }

      before do
        alice && bob
        create(:client_summary, client: shared_client)
        allow(redis).to receive(:get).with(shared_key).and_return(nil)
        allow(redis).to receive(:set)
      end

      it "returns the existing summary without making a Gemini API call" do
        expect(GeminiClient).not_to receive(:generate_client_summary)
        result = ClientSummaryService.generate(shared_client.id.to_s)
        expect(result[:summary]).to eq("Test client summary")
      end

      it "warms the Redis cache so any subsequent request by any accountant is a pure cache hit" do
        expect(redis).to receive(:set).with(shared_key, anything)
        ClientSummaryService.generate(shared_client.id.to_s)
      end
    end
  end
end
