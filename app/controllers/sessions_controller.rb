class SessionsController < WebController
  def new
  end

  def create
    accountant = Accountant.find_by(email: params[:email])

    unless accountant&.authenticate(params[:password])
      flash.now[:alert] = "Invalid email or password"
      return render :new, status: :unprocessable_entity
    end

    session[:token] = JwtService.encode(accountant.id)
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to sign_in_path
  end
end
