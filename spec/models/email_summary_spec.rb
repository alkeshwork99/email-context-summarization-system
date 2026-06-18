require "rails_helper"

RSpec.describe EmailSummary, type: :model do
  describe "associations" do
    it "belongs to an email thread" do
      thread = create(:email_thread)
      summary = create(:email_summary, email_thread: thread)
      expect(summary.email_thread).to eq(thread)
    end
  end

  describe "uniqueness" do
    it "enforces one summary per thread at the database level" do
      thread = create(:email_thread)
      create(:email_summary, email_thread: thread)
      duplicate = build(:email_summary, email_thread: thread)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "fields" do
    it "stores actors as a JSON array" do
      summary = create(:email_summary, actors: [ "Alice", "Bob" ])
      expect(summary.reload.actors).to eq([ "Alice", "Bob" ])
    end

    it "stores concluded_discussions as a JSON array" do
      summary = create(:email_summary, concluded_discussions: [ "Filed taxes" ])
      expect(summary.reload.concluded_discussions).to eq([ "Filed taxes" ])
    end

    it "stores open_action_items as a JSON array" do
      summary = create(:email_summary, open_action_items: [ "Submit W2" ])
      expect(summary.reload.open_action_items).to eq([ "Submit W2" ])
    end
  end
end
