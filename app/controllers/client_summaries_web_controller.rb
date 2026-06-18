class ClientSummariesWebController < WebController
  before_action :authenticate_web_request
  before_action :set_client

  def show
    add_request_span_attributes(
      "client.id" => @client.id,
      "client.email" => @client.email,
      "client.name" => @client.name
    )
    @summary = ClientSummaryService.generate(@client.id.to_s)
  end

  def refresh
    add_request_span_attributes(
      "client.id" => @client.id,
      "client.email" => @client.email,
      "client.name" => @client.name
    )
    ClientSummaryRefreshService.refresh(@client.id.to_s)
    redirect_to client_summary_web_path(@client)
  end

  private

  def set_client
    @client = scope_clients.find(params[:id])
  end
end
