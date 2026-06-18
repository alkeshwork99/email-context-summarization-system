require "rails_helper"

describe GeminiClient, :observability do
  let(:success_response) do
    instance_double(
      Faraday::Response,
      body: {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: {
                    actors: ["Alice"],
                    concluded_discussions: [],
                    open_action_items: [],
                    summary: "Done."
                  }.to_json
                }
              ]
            }
          }
        ]
      }.to_json
    )
  end
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:info_logs) { [] }
  let(:error_logs) { [] }

  before do
    allow(GeminiClient).to receive(:generate_summary).and_call_original
    allow(GeminiClient).to receive(:generate_client_summary).and_call_original
    allow(Rails).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info) { |payload| info_logs << payload }
    allow(logger).to receive(:error) { |payload| error_logs << payload }
  end

  it "logs the start and finish of a successful call" do
    connection = instance_double(Faraday::Connection)
    allow(connection).to receive(:post).and_return(success_response)
    allow(GeminiClient).to receive(:connection).and_return(connection)

    Observability.with_span("llm_summarization_call") do
      GeminiClient.generate_summary("hello")
    end

    expect(info_logs.size).to eq(2)
    first_entry = parse_log_entry(info_logs.first)
    second_entry = parse_log_entry(info_logs.last)
    expect(first_entry["message"]).to eq("LLM call started")
    expect(second_entry["message"]).to eq("LLM call finished")
  end

  it "records exception details and marks the active span as error on failure" do
    connection = instance_double(Faraday::Connection)
    allow(connection).to receive(:post).and_return(instance_double(Faraday::Response, body: { error: { code: 429 } }.to_json))
    allow(GeminiClient).to receive(:connection).and_return(connection)

    expect {
      Observability.with_span("llm_summarization_call") do
        GeminiClient.generate_summary("hello")
      end
    }.to raise_error(GeminiClient::RateLimitError)

    span = span_named("llm_summarization_call")
    expect(span.status.code).to eq(OpenTelemetry::Trace::Status::ERROR)
    expect(parse_log_entry(error_logs.last)["message"]).to eq("LLM call failed")
  end
end
