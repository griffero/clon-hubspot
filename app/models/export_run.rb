class ExportRun < ApplicationRecord
  has_many :export_checkpoints, dependent: :destroy
  has_many :export_tables, dependent: :destroy

  enum :mode, { full: "full", incremental: "incremental" }, validate: true
  enum :status, {
    queued: 0,
    running: 1,
    succeeded: 2,
    failed: 3,
    retry_exhausted: 4
  }, validate: true

  validates :run_id, :portal_id, presence: true
  validates :run_id, uniqueness: true

  scope :active, -> { where(status: [:queued, :running]) }

  def start!
    update!(status: :running, started_at: Time.current, last_heartbeat_at: Time.current)
  end

  def heartbeat!
    update!(last_heartbeat_at: Time.current)
  end

  def finish!(final_status: :succeeded, error_message: nil)
    update!(status: final_status, finished_at: Time.current, error_message: error_message)
  end
end
