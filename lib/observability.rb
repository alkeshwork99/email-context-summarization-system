require "json"

module Observability
  TRACER_NAME = "email_context_api".freeze
  SERVICE_NAME = "email-context-api".freeze

  class << self
    def tracer
      OpenTelemetry.tracer_provider.tracer(TRACER_NAME)
    end

    def with_span(name, attributes: {})
      tracer.in_span(name) do |span|
        add_attributes(attributes, span: span)
        yield span
      end
    end

    def add_attributes(attributes, span: current_span)
      return unless valid_span?(span)

      normalize_attributes(attributes).each do |key, value|
        span.set_attribute(key, value)
      end
    end

    def record_exception(error, span: current_span)
      return unless valid_span?(span)

      span.record_exception(error)
    end

    def set_status(code, description = nil, span: current_span)
      return unless valid_span?(span)

      span.status = case code.to_sym
      when :ok
        OpenTelemetry::Trace::Status.ok(description.to_s)
      when :error
        OpenTelemetry::Trace::Status.error(description.to_s)
      else
        OpenTelemetry::Trace::Status.unset(description.to_s)
      end
    end

    def increment_counter(name, attributes: {})
      counter_store.increment(name, normalize_attributes(attributes))
    end

    def counter_value(name, attributes: {})
      counter_store.value(name, normalize_attributes(attributes))
    end

    def reset_counters!
      counter_store.reset!
    end

    def log_info(message, attributes: {})
      log(:info, message, attributes)
    end

    def log_error(message, error:, attributes: {})
      log(
        :error,
        message,
        attributes.merge(
          "error.class" => error.class.name,
          "error.message" => error.message
        )
      )
    end

    def current_span
      OpenTelemetry::Trace.current_span
    end

    private

    def log(level, message, attributes)
      Rails.logger.public_send(level, JSON.generate(
        severity: level.to_s.upcase,
        message: message,
        timestamp: Time.current.iso8601(6),
        trace_id: trace_id,
        span_id: span_id,
        attributes: normalize_attributes(attributes)
      ))
    end

    def trace_id
      span_context = current_span.context
      return nil unless span_context.valid?

      span_context.hex_trace_id
    rescue NoMethodError
      nil
    end

    def span_id
      span_context = current_span.context
      return nil unless span_context.valid?

      span_context.hex_span_id
    rescue NoMethodError
      nil
    end

    def valid_span?(span)
      span && span.context.valid?
    rescue NoMethodError
      false
    end

    def normalize_attributes(attributes)
      attributes.each_with_object({}) do |(key, value), memo|
        next if value.nil?

        memo[key.to_s] = normalize_value(value)
      end
    end

    def normalize_value(value)
      case value
      when String, Integer, Float, TrueClass, FalseClass
        value
      when Array
        value.map { |item| normalize_value(item) }
      else
        value.to_s
      end
    end

    def counter_store
      @counter_store ||= CounterStore.new
    end
  end

  class CounterStore
    def initialize
      @counts = Hash.new(0)
      @mutex = Mutex.new
    end

    def increment(name, attributes)
      @mutex.synchronize do
        @counts[counter_key(name, attributes)] += 1
      end
    end

    def value(name, attributes)
      @mutex.synchronize do
        @counts[counter_key(name, attributes)]
      end
    end

    def reset!
      @mutex.synchronize { @counts.clear }
    end

    private

    def counter_key(name, attributes)
      [name.to_s, attributes.sort_by(&:first)]
    end
  end
end
