class CreateClientSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :client_summaries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :client_id,              null: false
      t.text     :summary_encrypted,      null: false
      t.json     :actors
      t.json     :concluded_discussions
      t.json     :open_action_items
      t.integer  :emails_analyzed_count,  null: false
      t.integer  :threads_analyzed_count, null: false
      t.datetime :last_refreshed_at,      null: false

      t.timestamps
    end

    add_index :client_summaries, :client_id, unique: true
    add_foreign_key :client_summaries, :clients
  end
end
