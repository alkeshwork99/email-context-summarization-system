class EmailThreadsController < WebController
  before_action :authenticate_web_request

  def show
    @thread = scope_threads.includes(:client).find(params[:id])
    @messages = @thread.email_messages.order(:sent_at)
  end
end
