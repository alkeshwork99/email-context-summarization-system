class MockEmailService
  class << self
    def fetch_thread(conversation_id)
      EmailThread
        .includes(:email_messages)
        .find_by!(conversation_id: conversation_id)
    end

    def fetch_messages(email_thread)
      email_thread.email_messages.sort_by(&:sent_at)
    end

    def fetch_client_threads(client)
      client.email_threads.includes(:email_messages, :email_summary)
    end

    def build_graph_message(email_message)
      {
        graph_message_id:  email_message.graph_message_id,
        conversation_id:   email_message.email_thread.conversation_id,
        subject:           email_message.subject,
        from: {
          emailAddress: { address: email_message.from_email }
        },
        toRecipients:      email_message.to_emails,
        ccRecipients:      email_message.cc_emails,
        body: {
          content: email_message.body
        },
        sentDateTime:      email_message.sent_at,
        receivedDateTime:  email_message.received_at,
        internetMessageId: email_message.message_id
      }
    end

    def fetch_thread_messages(conversation_id)
      thread   = fetch_thread(conversation_id)
      messages = fetch_messages(thread)
      messages.map { |msg| build_graph_message(msg) }
    end
  end
end
