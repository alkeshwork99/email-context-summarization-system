require "rails_helper"

describe "Summary refresh observability", :observability do
  let(:client) { create(:client, email: "alice@example.com", name: "Alice Brown") }
  let(:thread) { create(:email_thread, client: client, conversation_id: "conv_refresh", subject: "Refresh me") }
  let(:result) do
    {
      actors: ["Alice"],
      concluded_discussions: [],
      open_action_items: [],
      summary: "Fresh summary."
    }
  end

  before do
    allow(SummaryService).to receive(:generate).and_return(result)
  end

  it "emits refresh spans and increments the refresh counter" do
    SummaryRefreshService.refresh(thread.conversation_id)

    expect(span_named("refresh_email_summary").attributes).to include(
      "thread.conversation_id" => thread.conversation_id,
      "thread.id" => thread.id,
      "client.id" => client.id,
      "firm.id" => client.firm_id
    )
    expect(span_named("delete_existing_summary").attributes).to eq({})
    expect(span_named("regenerate_summary").attributes).to eq({})
    expect(Observability.counter_value("email_summary_refresh_total", attributes: { "firm.id" => client.firm_id.to_s })).to eq(1)
  end
end
