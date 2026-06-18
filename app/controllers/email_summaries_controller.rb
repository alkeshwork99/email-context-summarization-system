class EmailSummariesController < ApplicationController
  before_action :authenticate_request

  def show
    authorize_thread!(params[:conversation_id])
    add_request_span_attributes("thread.conversation_id" => params[:conversation_id])
    result = SummaryService.generate(params[:conversation_id])
    render json: result
  end

  def refresh
    authorize_thread!(params[:conversation_id])
    add_request_span_attributes("thread.conversation_id" => params[:conversation_id])
    result = SummaryRefreshService.refresh(params[:conversation_id])
    render json: result
  end

  private

  def authorize_thread!(conversation_id)
    scope_threads.find_by!(conversation_id: conversation_id)
  end
end
