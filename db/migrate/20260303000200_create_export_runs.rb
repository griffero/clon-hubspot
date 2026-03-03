class CreateExportRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :export_runs do |t|
      t.string :run_id, null: false
      t.string :portal_id, null: false
      t.string :mode, null: false, default: "full"
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :last_heartbeat_at
      t.integer :retry_count, null: false, default: 0
      t.integer :total_records, null: false, default: 0
      t.jsonb :stats, null: false, default: {}
      t.text :error_message

      t.timestamps
    end

    add_index :export_runs, :run_id, unique: true
    add_index :export_runs, [:portal_id, :created_at]
    add_index :export_runs, :status
  end
end
