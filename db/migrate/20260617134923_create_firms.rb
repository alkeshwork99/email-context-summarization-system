class CreateFirms < ActiveRecord::Migration[8.1]
  def change
    create_table :firms, id: :uuid do |t|
      t.string :name
      t.string :domain

      t.timestamps
    end

    add_index :firms, :domain, unique: true
  end
end
