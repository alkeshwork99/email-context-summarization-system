class CreateEmailThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :email_threads, id: :uuid do |t|
      t.references :client,
                   null: false,
                   type: :uuid,
                   foreign_key: true

      t.string :conversation_id,
               null: false

      t.string :subject

      t.timestamps
    end

    add_index :email_threads,
              [ :client_id, :conversation_id ],
              unique: true
  end
end
