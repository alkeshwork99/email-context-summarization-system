require "rails_helper"

RSpec.describe EmailMessage, type: :model do
  describe "associations" do
    it "belongs to an email thread" do
      thread = create(:email_thread)
      message = create(:email_message, email_thread: thread)
      expect(message.email_thread).to eq(thread)
    end

    it "belongs to an accountant optionally" do
      message = create(:email_message, accountant: nil)
      expect(message.accountant).to be_nil
    end

    it "associates with an accountant when present" do
      accountant = create(:accountant)
      message = create(:email_message, accountant: accountant)
      expect(message.accountant).to eq(accountant)
    end
  end

  describe "uniqueness" do
    it "enforces unique graph_message_id at the database level" do
      create(:email_message, graph_message_id: "gm-001")
      duplicate = build(:email_message, graph_message_id: "gm-001")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "enforces unique message_id at the database level" do
      create(:email_message, message_id: "<unique@example.com>")
      duplicate = build(:email_message, message_id: "<unique@example.com>")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
