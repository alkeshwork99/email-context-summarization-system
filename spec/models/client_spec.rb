require "rails_helper"

RSpec.describe Client, type: :model do
  describe "associations" do
    it "belongs to a firm" do
      firm = create(:firm)
      client = create(:client, firm: firm)
      expect(client.firm).to eq(firm)
    end

    it "has many email threads" do
      client = create(:client)
      thread = create(:email_thread, client: client)
      expect(client.email_threads).to include(thread)
    end

    it "destroys email threads when client is destroyed" do
      client = create(:client)
      create(:email_thread, client: client)
      expect { client.destroy }.to change(EmailThread, :count).by(-1)
    end
  end

  describe "uniqueness" do
    it "enforces unique email per firm at the database level" do
      firm = create(:firm)
      create(:client, firm: firm, email: "dup@client.com")
      duplicate = build(:client, firm: firm, email: "dup@client.com")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same email across different firms" do
      email = "shared@example.com"
      create(:client, firm: create(:firm), email: email)
      expect { create(:client, firm: create(:firm), email: email) }.not_to raise_error
    end
  end
end
