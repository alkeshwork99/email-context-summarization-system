class EmailSummariesWebController < WebController
  before_action :authenticate_web_request
  before_action :set_thread

  def show
    add_request_span_attributes(
      "thread.conversation_id" => @thread.conversation_id,
      "thread.id" => @thread.id,
      "client.id" => @thread.client_id
    )
    @summary = SummaryService.generate(@thread.conversation_id)
  end

  def refresh
    add_request_span_attributes(
      "thread.conversation_id" => @thread.conversation_id,
      "thread.id" => @thread.id,
      "client.id" => @thread.client_id
    )
    SummaryRefreshService.refresh(@thread.conversation_id)
    redirect_to email_summary_web_path(@thread)
  end

  private

  def set_thread
    @thread = scope_threads.find(params[:id])
  end
end
