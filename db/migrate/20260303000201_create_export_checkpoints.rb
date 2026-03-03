class CreateExportCheckpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :export_checkpoints do |t|
      t.references :export_run, null: false, foreign_key: true
      t.string :portal_id, null: false
      t.string :extractor_key, null: false
      t.integer :status, null: false, default: 0
      t.string :cursor
      t.datetime :high_watermark
      t.integer :records_exported, null: false, default: 0
      t.integer :retries, null: false, default: 0
      t.datetime :last_synced_at
      t.text :last_error
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :export_checkpoints, [:export_run_id, :portal_id, :extractor_key], unique: true, name: "idx_export_checkpoints_run_portal_key"
    add_index :export_checkpoints, :status
  end
end
