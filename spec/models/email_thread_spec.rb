require "rails_helper"

RSpec.describe EmailThread, type: :model do
  describe "associations" do
    it "belongs to a client" do
      client = create(:client)
      thread = create(:email_thread, client: client)
      expect(thread.client).to eq(client)
    end

    it "has many email messages" do
      thread = create(:email_thread)
      message = create(:email_message, email_thread: thread)
      expect(thread.email_messages).to include(message)
    end

    it "destroys email messages when thread is destroyed" do
      thread = create(:email_thread)
      create(:email_message, email_thread: thread)
      expect { thread.destroy }.to change(EmailMessage, :count).by(-1)
    end

    it "has one email summary" do
      thread = create(:email_thread)
      summary = create(:email_summary, email_thread: thread)
      expect(thread.email_summary).to eq(summary)
    end

    it "destroys email summary when thread is destroyed" do
      thread = create(:email_thread)
      create(:email_summary, email_thread: thread)
      expect { thread.destroy }.to change(EmailSummary, :count).by(-1)
    end
  end

  describe "uniqueness" do
    it "enforces unique conversation_id per client at the database level" do
      client = create(:client)
      create(:email_thread, client: client, conversation_id: "conv-123")
      duplicate = build(:email_thread, client: client, conversation_id: "conv-123")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same conversation_id for different clients" do
      create(:email_thread, client: create(:client), conversation_id: "conv-123")
      expect { create(:email_thread, client: create(:client), conversation_id: "conv-123") }.not_to raise_error
    end
  end
end
