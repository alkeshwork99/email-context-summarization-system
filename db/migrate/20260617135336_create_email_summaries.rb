class CreateEmailSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :email_summaries, id: :uuid do |t|
      t.references :thread,
                   null: false,
                   type: :uuid,
                   foreign_key: {
                     to_table: :email_threads
                   },
                   index: {
                     unique: true
                   }

      t.text :summary_encrypted,
             null: false

      t.json :actors

      t.json :concluded_discussions

      t.json :open_action_items

      t.integer :emails_analyzed_count,
                null: false

      t.datetime :last_refreshed_at,
                 null: false

      t.timestamps
    end
  end
end
