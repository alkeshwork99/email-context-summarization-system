class ApplicationController < ActionController::API
  include FirmScoped

  rescue_from JWT::DecodeError,             with: :unauthorized
  rescue_from JWT::ExpiredSignature,        with: :unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from GeminiClient::RateLimitError,         with: :ai_quota_exceeded
  rescue_from GeminiClient::RequestInProgressError, with: :ai_in_progress

  private

  def authenticate_request
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
    @current_accountant = AuthenticationService.authenticate(token)
    add_request_span_attributes
  end

  def add_request_span_attributes(attributes = {})
    Observability.add_attributes({
      "http.route" => request.path,
      "accountant.id" => current_accountant&.id,
      "accountant.role" => current_accountant&.role,
      "firm.id" => current_accountant&.firm_id
    }.merge(attributes))
  end

  def unauthorized(_exception)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def not_found(_exception)
    render json: { error: "Not Found" }, status: :not_found
  end

  def forbidden(_exception = nil)
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def ai_quota_exceeded(_exception)
    render json: { error: "AI quota exceeded — try again later" }, status: :service_unavailable
  end

  def ai_in_progress(_exception)
    render json: { error: "Summary is already being generated — please try again in a moment." },
           status: :service_unavailable
  end
end
