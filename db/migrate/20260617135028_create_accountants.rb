class CreateAccountants < ActiveRecord::Migration[8.1]
  def change
    create_table :accountants, id: :uuid do |t|
      t.references :firm,
                   null: false,
                   type: :uuid,
                   foreign_key: true

      t.string :name

      t.string :email, null: false

      t.string :password_digest

      t.string :role

      t.boolean :is_active,
                null: false,
                default: true

      t.timestamps
    end

    add_index :accountants,
              [ :firm_id, :email ],
              unique: true
  end
end
