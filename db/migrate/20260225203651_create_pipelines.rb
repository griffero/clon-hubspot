class CreatePipelines < ActiveRecord::Migration[8.0]
  def change
    create_table :pipelines do |t|
      t.string :hubspot_id
      t.string :label
      t.integer :display_order
      t.boolean :active

      t.timestamps
    end
    add_index :pipelines, :hubspot_id, unique: true
  end
end
