require "rails_helper"

RSpec.describe Accountant, type: :model do
  describe "associations" do
    it "belongs to a firm" do
      firm = create(:firm)
      accountant = create(:accountant, firm: firm)
      expect(accountant.firm).to eq(firm)
    end

    it "has many email messages" do
      accountant = create(:accountant)
      message = create(:email_message, accountant: accountant)
      expect(accountant.email_messages).to include(message)
    end

    it "nullifies email messages when accountant is destroyed" do
      accountant = create(:accountant)
      message = create(:email_message, accountant: accountant)
      accountant.destroy
      expect(message.reload.accountant_id).to be_nil
    end
  end

  describe "has_secure_password" do
    it "authenticates with the correct password" do
      accountant = create(:accountant, password: "secret123")
      expect(accountant.authenticate("secret123")).to eq(accountant)
    end

    it "rejects an incorrect password" do
      accountant = create(:accountant, password: "secret123")
      expect(accountant.authenticate("wrong")).to be_falsy
    end
  end

  describe "role predicates" do
    it "returns true for admin? when role is admin" do
      accountant = build(:accountant, :admin)
      expect(accountant.admin?).to be true
      expect(accountant.superuser?).to be false
      expect(accountant.accountant?).to be false
    end

    it "returns true for superuser? when role is superuser" do
      accountant = build(:accountant, :superuser)
      expect(accountant.superuser?).to be true
      expect(accountant.admin?).to be false
      expect(accountant.accountant?).to be false
    end

    it "returns true for accountant? when role is accountant" do
      accountant = build(:accountant)
      expect(accountant.accountant?).to be true
      expect(accountant.admin?).to be false
      expect(accountant.superuser?).to be false
    end
  end

  describe "uniqueness" do
    it "enforces unique email per firm at the database level" do
      firm = create(:firm)
      create(:accountant, firm: firm, email: "dup@firm.com")
      duplicate = build(:accountant, firm: firm, email: "dup@firm.com")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same email across different firms" do
      email = "shared@example.com"
      create(:accountant, firm: create(:firm), email: email)
      expect { create(:accountant, firm: create(:firm), email: email) }.not_to raise_error
    end
  end
end
