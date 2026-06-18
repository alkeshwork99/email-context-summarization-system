require "rails_helper"

RSpec.describe ClientSummary, type: :model do
  describe "associations" do
    it "belongs to a client" do
      client  = create(:client)
      summary = create(:client_summary, client: client)
      expect(summary.client).to eq(client)
    end
  end

  describe "uniqueness" do
    it "enforces one summary per client at the database level" do
      client = create(:client)
      create(:client_summary, client: client)
      duplicate = build(:client_summary, client: client)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "fields" do
    it "stores actors as a JSON array" do
      summary = create(:client_summary, actors: [ "Alice Brown", "John Smith" ])
      expect(summary.reload.actors).to eq([ "Alice Brown", "John Smith" ])
    end

    it "stores concluded_discussions as a JSON array" do
      summary = create(:client_summary, concluded_discussions: [ "W-2 received" ])
      expect(summary.reload.concluded_discussions).to eq([ "W-2 received" ])
    end

    it "stores open_action_items as a JSON array" do
      summary = create(:client_summary, open_action_items: [ "Submit 1099-NEC" ])
      expect(summary.reload.open_action_items).to eq([ "Submit 1099-NEC" ])
    end

    it "tracks threads_analyzed_count separately from emails_analyzed_count" do
      summary = create(:client_summary, emails_analyzed_count: 15, threads_analyzed_count: 3)
      expect(summary.reload.emails_analyzed_count).to eq(15)
      expect(summary.reload.threads_analyzed_count).to eq(3)
    end
  end
end
