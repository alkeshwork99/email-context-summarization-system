FactoryBot.define do
  factory :client_summary do
    client
    summary_encrypted      { EncryptionService.encrypt("Test client summary") }
    actors                 { [ "Alice Brown", "John Smith", "Mary Johnson" ] }
    concluded_discussions  { [ "W-2 documents received and verified", "Estimated tax payments confirmed" ] }
    open_action_items      { [ "Submit 1099-NEC forms", "Submit home office receipts" ] }
    emails_analyzed_count  { 9 }
    threads_analyzed_count { 3 }
    last_refreshed_at      { Time.current }
  end
end
