require "rails_helper"

describe "POST /login" do
  let(:firm)       { create(:firm) }
  let(:accountant) { create(:accountant, firm: firm, email: "test@example.com", password: "password123") }

  before { accountant }

  context "with valid credentials" do
    it "returns 200 with a token and account details" do
      post "/login", params: { email: "test@example.com", password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_a(String)
      expect(body["role"]).to eq(accountant.role)
      expect(body["name"]).to eq(accountant.name)
      expect(body["email"]).to eq(accountant.email)
    end
  end

  context "with wrong password" do
    it "returns 401" do
      post "/login", params: { email: "test@example.com", password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with unknown email" do
    it "returns 401" do
      post "/login", params: { email: "nobody@example.com", password: "password123" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
