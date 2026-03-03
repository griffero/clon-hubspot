class CreateExportTables < ActiveRecord::Migration[8.0]
  def change
    create_table :export_tables do |t|
      t.references :export_run, null: false, foreign_key: true
      t.string :extractor_key, null: false
      t.string :object_type, null: false
      t.string :file_path, null: false
      t.integer :expected_count
      t.integer :extracted_count, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :checksum
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :export_tables, [:export_run_id, :extractor_key], unique: true
    add_index :export_tables, :status
  end
end
