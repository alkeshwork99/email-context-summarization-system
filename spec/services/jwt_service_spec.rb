require "rails_helper"

describe JwtService do
  describe ".encode / .decode" do
    it "round-trips the accountant_id" do
      accountant = create(:accountant)
      token      = JwtService.encode(accountant.id)
      payload    = JwtService.decode(token)
      expect(payload["accountant_id"]).to eq(accountant.id)
    end
  end

  describe ".decode" do
    it "raises JWT::ExpiredSignature for an expired token" do
      accountant = create(:accountant)
      token = JWT.encode(
        { accountant_id: accountant.id, exp: 1.minute.ago.to_i },
        ENV["JWT_SECRET"],
        "HS256"
      )
      expect { JwtService.decode(token) }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
