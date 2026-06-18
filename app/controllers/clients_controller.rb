class ClientsController < WebController
  before_action :authenticate_web_request

  def index
    add_request_span_attributes
    @clients = scope_clients.includes(:firm).order(:name)
  end

  def show
    @client = scope_clients.find(params[:id])
    add_request_span_attributes(
      "client.id" => @client.id,
      "client.email" => @client.email,
      "client.name" => @client.name
    )
    @threads = @client.email_threads.order(:created_at)
  end
end
