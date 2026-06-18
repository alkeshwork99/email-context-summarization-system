class AuthenticationService
  class << self
    def authenticate(token)
      payload = JwtService.decode(token)
      Accountant.find(payload["accountant_id"])
    end
  end
end
