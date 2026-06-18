require Rails.root.join("lib/observability")
require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rack"

OpenTelemetry::SDK.configure do |config|
  config.service_name = Observability::SERVICE_NAME
  config.resource = OpenTelemetry::SDK::Resources::Resource.create(
    "service.name" => Observability::SERVICE_NAME,
    "service.namespace" => "email-context-api",
    "deployment.environment" => Rails.env.to_s
  )
  config.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
    )
  )
  config.use "OpenTelemetry::Instrumentation::Rack", use_rack_events: false
end
