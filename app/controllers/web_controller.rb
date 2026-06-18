class WebController < ActionController::Base
  include FirmScoped

  protect_from_forgery with: :exception

  layout "application"

  helper_method :current_accountant

  rescue_from ActiveRecord::RecordNotFound,         with: :not_found
  rescue_from GeminiClient::RateLimitError,         with: :ai_quota_exceeded
  rescue_from GeminiClient::RequestInProgressError, with: :ai_in_progress

  private

  def not_found(_exception)
    flash[:alert] = "The requested resource was not found."
    redirect_to root_path
  end

  def ai_quota_exceeded(_exception)
    flash[:alert] = "AI quota exceeded — the Gemini free tier allows 20 requests per day. Please try again tomorrow."
    redirect_back(fallback_location: root_path)
  end

  def ai_in_progress(_exception)
    flash[:alert] = "A summary is currently being generated. Please try again shortly."
    redirect_back(fallback_location: root_path)
  end

  def authenticate_web_request
    token = session[:token]
    return redirect_to(sign_in_path) unless token

    @current_accountant = AuthenticationService.authenticate(token)
    add_request_span_attributes
  rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
    reset_session
    redirect_to sign_in_path
  end

  def current_accountant
    @current_accountant
  end

  def add_request_span_attributes(attributes = {})
    Observability.add_attributes({
      "http.route" => request.path,
      "accountant.id" => current_accountant&.id,
      "accountant.role" => current_accountant&.role,
      "firm.id" => current_accountant&.firm_id
    }.merge(attributes))
  end
end
