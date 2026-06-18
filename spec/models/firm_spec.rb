require "rails_helper"

RSpec.describe Firm, type: :model do
  describe "associations" do
    it "has many accountants" do
      firm = create(:firm)
      accountant = create(:accountant, firm: firm)
      expect(firm.accountants).to include(accountant)
    end

    it "destroys accountants when firm is destroyed" do
      firm = create(:firm)
      create(:accountant, firm: firm)
      expect { firm.destroy }.to change(Accountant, :count).by(-1)
    end

    it "has many clients" do
      firm = create(:firm)
      client = create(:client, firm: firm)
      expect(firm.clients).to include(client)
    end

    it "destroys clients when firm is destroyed" do
      firm = create(:firm)
      create(:client, firm: firm)
      expect { firm.destroy }.to change(Client, :count).by(-1)
    end
  end

  describe "uniqueness" do
    it "enforces unique domain at the database level" do
      create(:firm, domain: "acme.com")
      duplicate = build(:firm, domain: "acme.com")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
