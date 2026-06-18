FactoryBot.define do
  factory :email_summary do
    email_thread
    summary_encrypted     { EncryptionService.encrypt("Test summary") }
    actors                { [ "Alice", "Bob" ] }
    concluded_discussions { [ "Discussed taxes" ] }
    open_action_items     { [ "Submit W2" ] }
    emails_analyzed_count { 1 }
    last_refreshed_at     { Time.current }
  end
end
