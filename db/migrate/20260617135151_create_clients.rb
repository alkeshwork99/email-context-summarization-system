class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients, id: :uuid do |t|
      t.references :firm,
                   null: false,
                   type: :uuid,
                   foreign_key: true

      t.string :name

      t.string :email,
               null: false

      t.string :phone

      t.string :status

      t.timestamps
    end

    add_index :clients,
              [ :firm_id, :email ],
              unique: true
  end
end
