FactoryBot.define do
  factory :email_thread do
    client
    conversation_id { SecureRandom.uuid }
    subject         { Faker::Lorem.sentence }
  end
end
