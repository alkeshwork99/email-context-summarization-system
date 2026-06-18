class CreateEmailMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :email_messages, id: :uuid do |t|
      t.references :thread,
                   null: false,
                   type: :uuid,
                   foreign_key: {
                     to_table: :email_threads
                   }

      t.references :accountant,
                   type: :uuid,
                   foreign_key: true

      t.string :graph_message_id,
               null: false

      t.string :message_id,
               null: false

      t.string :from_email,
               null: false

      t.text :to_emails

      t.text :cc_emails

      t.string :subject

      t.text :body

      t.datetime :sent_at,
                 null: false

      t.datetime :received_at

      t.timestamps
    end

    add_index :email_messages,
              [ :thread_id, :sent_at ]

    add_index :email_messages,
              :graph_message_id,
              unique: true

    add_index :email_messages,
              :message_id,
              unique: true
  end
end
