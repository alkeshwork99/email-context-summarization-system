require "rails_helper"

describe SummaryService do
  describe ".generate" do
    context "when a Gemini call is already in progress for the same conversation" do
      let(:conversation_id) { "conv_lock_test" }
      let(:client) { create(:client, email: "lock@example.com", name: "Lock Client") }
      let(:thread) { create(:email_thread, client: client, conversation_id: conversation_id, subject: "Locked") }

      before do
        allow(SummaryCacheService).to receive(:fetch).and_return(nil)
        allow(SummaryCacheService).to receive(:lock).and_return(nil)
        allow(MockEmailService).to receive(:fetch_thread).and_return(thread)
      end

      it "raises GeminiClient::RequestInProgressError without calling Gemini" do
        expect(GeminiClient).not_to receive(:generate_summary)

        expect {
          SummaryService.generate(conversation_id)
        }.to raise_error(GeminiClient::RequestInProgressError)
      end
    end

    context "when a summary must be generated", :observability do
      let(:client) { create(:client, email: "alice@example.com", name: "Alice Brown") }
      let(:thread) do
        create(:email_thread, client: client, conversation_id: "conv_001", subject: "Tax documents")
      end
      let!(:older_message) do
        create(:email_message, email_thread: thread, from_email: "john@abc-cpa.com", body: "Please send your W-2", sent_at: 2.days.ago)
      end
      let!(:newer_message) do
        create(:email_message, email_thread: thread, from_email: "alice@example.com", body: "Attached the W-2", sent_at: 1.day.ago)
      end
      let(:gemini_result) do
        {
          actors: ["Alice Brown", "John Smith"],
          concluded_discussions: ["W-2 received"],
          open_action_items: [],
          summary: "The W-2 request was completed."
        }
      end

      before do
        allow(SummaryCacheService).to receive(:fetch).and_return(nil)
        allow(SummaryCacheService).to receive(:lock).and_return("OK")
        allow(SummaryCacheService).to receive(:unlock)
        allow(SummaryCacheService).to receive(:write).and_return(gemini_result)
        allow(GeminiClient).to receive(:generate_summary).and_return(gemini_result)
      end

      it "emits the expected spans, attributes, and counter" do
        SummaryService.generate(thread.conversation_id)

        root_span = span_named("generate_email_summary")
        load_span = span_named("load_messages")
        llm_span = span_named("llm_summarization_call")
        save_span = span_named("save_email_summary")

        expect(root_span.attributes).to include(
          "thread.conversation_id" => thread.conversation_id,
          "thread.id" => thread.id,
          "client.id" => client.id,
          "firm.id" => client.firm_id,
          "emails.count" => 2,
          "summary.source" => "generated",
          "summary.exists" => false
        )
        expect(load_span.attributes["thread.id"]).to eq(thread.id)
        expect(llm_span.attributes).to include(
          "llm.operation" => "thread_summary",
          "emails.count" => 2
        )
        expect(save_span.attributes["emails.count"]).to eq(2)
        expect(Observability.counter_value("email_summary_generation_total", attributes: { "firm.id" => client.firm_id.to_s })).to eq(1)
      end
    end

    context "when the summary is cached", :observability do
      let(:cached_result) do
        {
          actors: ["Alice"],
          concluded_discussions: [],
          open_action_items: [],
          summary: "Cached summary."
        }
      end

      before do
        allow(SummaryCacheService).to receive(:fetch).with("summary:conv_cached").and_return(cached_result)
      end

      it "annotates the root span and skips generation spans" do
        result = SummaryService.generate("conv_cached")

        expect(result).to eq(cached_result)
        expect(span_named("generate_email_summary").attributes).to include(
          "thread.conversation_id" => "conv_cached",
          "summary.source" => "cache",
          "summary.exists" => true
        )
        expect(span_named("load_messages")).to be_nil
        expect(span_named("llm_summarization_call")).to be_nil
      end
    end

    context "when the summary exists in the database", :observability do
      let(:client) { create(:client, email: "alice@example.com", name: "Alice Brown") }
      let(:thread) do
        create(:email_thread, client: client, conversation_id: "conv_db", subject: "Prior summary")
      end

      before do
        create(:email_summary, email_thread: thread)
        allow(SummaryCacheService).to receive(:fetch).and_return(nil)
        allow(SummaryCacheService).to receive(:write)
      end

      it "marks the span as a database hit" do
        result = SummaryService.generate(thread.conversation_id)

        expect(result[:summary]).to eq("Test summary")
        expect(span_named("generate_email_summary").attributes).to include(
          "summary.source" => "database",
          "summary.exists" => true,
          "thread.id" => thread.id,
          "client.id" => client.id
        )
        expect(span_named("load_messages")).to be_nil
      end
    end
  end
end
