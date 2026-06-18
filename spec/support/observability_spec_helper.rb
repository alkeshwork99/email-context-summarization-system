require "opentelemetry/sdk"

module ObservabilitySpecHelper
  def with_in_memory_spans
    original_provider = OpenTelemetry.tracer_provider
    exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
    provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    provider.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
    )
    OpenTelemetry.tracer_provider = provider

    yield exporter
  ensure
    OpenTelemetry.tracer_provider = original_provider
  end

  def span_exporter
    @span_exporter
  end

  def span_named(name)
    span_exporter.finished_spans.find { |span| span.name == name }
  end

  def spans_named(name)
    span_exporter.finished_spans.select { |span| span.name == name }
  end

  def parse_log_entry(payload)
    JSON.parse(payload)
  end
end
