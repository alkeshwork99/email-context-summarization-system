class ClientSummariesController < ApplicationController
  before_action :authenticate_request

  def show
    client = scope_clients.find(params[:client_id])
    add_request_span_attributes(
      "client.id" => client.id,
      "client.email" => client.email,
      "client.name" => client.name
    )
    result = ClientSummaryService.generate(client.id)
    render json: result
  end

  def refresh
    client = scope_clients.find(params[:client_id])
    add_request_span_attributes(
      "client.id" => client.id,
      "client.email" => client.email,
      "client.name" => client.name
    )
    result = ClientSummaryRefreshService.refresh(client.id)
    render json: result
  end
end
