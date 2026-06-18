class AuthController < ApplicationController
  def create
    accountant = Accountant.find_by(email: params[:email])

    unless accountant&.authenticate(params[:password])
      return render json: { error: "Invalid credentials" }, status: :unauthorized
    end

    token = JwtService.encode(accountant.id)

    render json: {
      token: token,
      role:  accountant.role,
      name:  accountant.name,
      email: accountant.email
    }
  end
end
