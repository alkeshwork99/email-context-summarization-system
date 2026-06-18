require "json"

class GeminiClient
  BASE_URL = "https://generativelanguage.googleapis.com"
  MODEL    = "gemini-2.5-flash"

  RateLimitError         = Class.new(StandardError)
  RequestInProgressError = Class.new(StandardError)

  class << self
    def generate_summary(thread_text)
      call_api(prompt(thread_text), operation: "thread_summary")
    end

    def generate_client_summary(summaries_text)
      call_api(client_prompt(summaries_text), operation: "client_summary")
    end

    private

    def call_api(full_prompt, operation:)
      Observability.add_attributes({
        "llm.provider" => "google",
        "llm.model" => MODEL,
        "llm.operation" => operation
      })
      Observability.log_info("LLM call started", attributes: {
        "llm.provider" => "google",
        "llm.model" => MODEL,
        "llm.operation" => operation
      })

      response = connection.post(endpoint) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(request_body(full_prompt))
      end

      parsed = JSON.parse(response.body)
      parts  = parsed.dig("candidates", 0, "content", "parts") || []
      text   = parts.filter_map { |p| p["text"] }.last
      if text.nil?
        error_code = parsed.dig("error", "code")
        raise RateLimitError, "AI quota exceeded — try again later"          if error_code == 429
        raise RateLimitError, "AI service temporarily unavailable"            if error_code == 503
        raise "Gemini API error: #{response.body}"
      end
      result = JSON.parse(text)
      Observability.log_info("LLM call finished", attributes: {
        "llm.provider" => "google",
        "llm.model" => MODEL,
        "llm.operation" => operation
      })

      {
        actors:                result["actors"],
        concluded_discussions: result["concluded_discussions"],
        open_action_items:     result["open_action_items"],
        summary:               result["summary"]
      }
    rescue StandardError => e
      Observability.record_exception(e)
      Observability.set_status(:error, e.message)
      Observability.log_error("LLM call failed", error: e, attributes: {
        "llm.provider" => "google",
        "llm.model" => MODEL,
        "llm.operation" => operation
      })
      raise
    end

    def connection
      Faraday.new(url: BASE_URL)
    end

    def endpoint
      "/v1beta/models/#{MODEL}:generateContent?key=#{ENV["GEMINI_API_KEY"]}"
    end

    def request_body(text)
      {
        contents: [
          {
            parts: [
              { text: text }
            ]
          }
        ]
      }
    end

    def prompt(thread_text)
      <<~PROMPT
        You are analyzing an email thread between accountants at a CPA firm and one of their clients.

        Context: multiple accountants at the firm may correspond with the same client across separate threads with no visibility into each other's conversations. This summary will be shared with the whole team so any accountant can instantly understand what happened here without reading every message.

        Return valid JSON only. No markdown. No code fences. No text outside the JSON object.

        Use exactly this schema:
        {
          "actors": [],
          "concluded_discussions": [],
          "open_action_items": [],
          "summary": ""
        }

        actors: full names of every person who sent or was explicitly mentioned — include both accountants and the client.
        concluded_discussions: topics, questions, or document requests that were explicitly confirmed complete in this thread. Only include items with clear confirmation — not assumptions.
        open_action_items: documents still awaited, questions unanswered, tasks not confirmed complete, or promised follow-ups not shown as done.
        summary: one or two sentences — state the thread topic, what was resolved, and what remains outstanding.

        Conversation:
        #{thread_text}
      PROMPT
    end

    def client_prompt(summaries_text)
      <<~PROMPT
        You are synthesizing thread-level email summaries for a single CPA firm client into one unified view.

        Context: multiple accountants at the same firm handle different aspects of this client's tax work in separate email threads. They have no visibility into each other's conversations. This causes two recurring coordination problems:
        1. Duplicate requests — the same document or action appears as an open item in more than one thread because different accountants each asked for it independently.
        2. Contradictions — one accountant marks a topic as resolved while another thread shows the same item is still missing or incomplete.

        Your job is to produce a single unified summary any accountant can read to immediately understand the client's complete status — without reading any individual thread.

        Return valid JSON only. No markdown. No code fences. No text outside the JSON object.

        Use exactly this schema:
        {
          "actors": [],
          "concluded_discussions": [],
          "open_action_items": [],
          "summary": ""
        }

        actors: full names of every person mentioned across all threads — all accountants and the client.
        concluded_discussions: items definitively resolved across all threads with no contradicting open reference in any other thread.
        open_action_items: all outstanding items across all threads. If the same item was requested by more than one accountant in separate threads, list it once and note the duplication. If a contradiction exists (resolved in one thread but open in another), list the item as still open and note the discrepancy explicitly.
        summary: two to three sentences covering the client's complete tax status, any coordination gaps found across threads, and what must happen next.

        Thread summaries:
        #{summaries_text}
      PROMPT
    end
  end
end
