class JwtService
  ALGORITHM = "HS256"

  class << self
    def encode(accountant_id)
      payload = {
        accountant_id: accountant_id,
        exp: 24.hours.from_now.to_i
      }
      JWT.encode(payload, ENV["JWT_SECRET"], ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(token, ENV["JWT_SECRET"], true, algorithms: [ ALGORITHM ])
      decoded.first
    end
  end
end
