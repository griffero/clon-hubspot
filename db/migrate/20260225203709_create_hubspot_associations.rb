class CreateHubspotAssociations < ActiveRecord::Migration[8.0]
  def change
    create_table :hubspot_associations do |t|
      t.string :from_object_type
      t.string :from_hubspot_id
      t.string :to_object_type
      t.string :to_hubspot_id

      t.timestamps
    end
    add_index :hubspot_associations, [:from_object_type, :from_hubspot_id, :to_object_type, :to_hubspot_id],
              unique: true, name: "index_hubspot_associations_uniqueness"
    add_index :hubspot_associations, [:to_object_type, :to_hubspot_id]
  end
end
