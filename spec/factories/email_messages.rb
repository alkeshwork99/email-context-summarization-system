FactoryBot.define do
  factory :email_message do
    email_thread
    graph_message_id { SecureRandom.uuid }
    message_id       { "<#{SecureRandom.uuid}@example.com>" }
    from_email       { Faker::Internet.email }
    to_emails        { Faker::Internet.email }
    body             { Faker::Lorem.paragraph }
    sent_at          { Time.current }
    received_at      { Time.current }
  end
end
