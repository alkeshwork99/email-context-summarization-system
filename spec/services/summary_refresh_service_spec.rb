require "rails_helper"

describe SummaryRefreshService do
  let(:redis)  { instance_double(Redis) }
  let(:client) { create(:client) }
  let(:thread) { create(:email_thread, client: client) }

  let(:stub_result) do
    {
      actors:                [ "Alice" ],
      concluded_discussions: [],
      open_action_items:     [ "Submit W2" ],
      summary:               "Refreshed summary."
    }
  end

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:del)
    allow(SummaryService).to receive(:generate).and_return(stub_result)
  end

  describe ".refresh" do
    it "deletes the thread-level Redis key" do
      expect(redis).to receive(:del).with("summary:#{thread.conversation_id}")
      SummaryRefreshService.refresh(thread.conversation_id)
    end

    it "deletes the client-level Redis key" do
      expect(redis).to receive(:del).with("client_summary:#{client.id}")
      SummaryRefreshService.refresh(thread.conversation_id)
    end

    it "destroys the existing thread EmailSummary record" do
      create(:email_summary, email_thread: thread)
      expect {
        SummaryRefreshService.refresh(thread.conversation_id)
      }.to change(EmailSummary, :count).by(-1)
    end

    it "destroys the existing ClientSummary record" do
      create(:client_summary, client: client)
      expect {
        SummaryRefreshService.refresh(thread.conversation_id)
      }.to change(ClientSummary, :count).by(-1)
    end

    it "does not raise when no EmailSummary exists" do
      expect { SummaryRefreshService.refresh(thread.conversation_id) }.not_to raise_error
    end

    it "does not raise when no ClientSummary exists" do
      expect { SummaryRefreshService.refresh(thread.conversation_id) }.not_to raise_error
    end

    it "regenerates the thread summary via SummaryService" do
      expect(SummaryService).to receive(:generate).with(thread.conversation_id)
      SummaryRefreshService.refresh(thread.conversation_id)
    end

    it "returns the fresh thread summary" do
      result = SummaryRefreshService.refresh(thread.conversation_id)
      expect(result[:summary]).to eq("Refreshed summary.")
    end
  end
end
