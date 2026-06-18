require "rails_helper"

describe ClientSummaryRefreshService, :observability do
  let(:client) { create(:client, email: "alice@example.com", name: "Alice Brown") }
  let(:result) do
    {
      actors: ["Alice"],
      concluded_discussions: [],
      open_action_items: [],
      summary: "Fresh client summary."
    }
  end

  before do
    allow(ClientSummaryService).to receive(:generate).and_return(result)
  end

  it "emits refresh spans and increments the refresh counter" do
    ClientSummaryRefreshService.refresh(client.id)

    expect(span_named("refresh_client_summary").attributes).to include(
      "client.id" => client.id,
      "client.email" => client.email,
      "client.name" => client.name,
      "firm.id" => client.firm_id
    )
    expect(span_named("delete_existing_summary")).not_to be_nil
    expect(span_named("regenerate_summary")).not_to be_nil
    expect(Observability.counter_value("client_summary_refresh_total", attributes: { "firm.id" => client.firm_id.to_s })).to eq(1)
  end
end
