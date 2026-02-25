class CreateDeals < ActiveRecord::Migration[8.0]
  def change
    create_table :deals do |t|
      t.string :hubspot_id
      t.string :name
      t.decimal :amount
      t.date :close_date
      t.references :stage, null: false, foreign_key: true
      t.references :pipeline, null: false, foreign_key: true
      t.string :hubspot_owner_id

      t.timestamps
    end
    add_index :deals, :hubspot_id, unique: true
  end
end
