class CreateStages < ActiveRecord::Migration[8.0]
  def change
    create_table :stages do |t|
      t.string :hubspot_id
      t.references :pipeline, null: false, foreign_key: true
      t.string :label
      t.integer :display_order
      t.decimal :probability
      t.boolean :is_closed

      t.timestamps
    end
    add_index :stages, :hubspot_id, unique: true
  end
end
