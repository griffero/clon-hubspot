class ExportCheckpoint < ApplicationRecord
  belongs_to :export_run

  enum :status, {
    queued: 0,
    running: 1,
    succeeded: 2,
    failed: 3,
    retry_exhausted: 4
  }, validate: true

  validates :portal_id, :extractor_key, presence: true

  def mark_running!
    update!(status: :running, last_error: nil)
  end

  def mark_succeeded!(high_watermark: nil)
    update!(
      status: :succeeded,
      high_watermark: high_watermark || self.high_watermark,
      last_synced_at: Time.current,
      last_error: nil
    )
  end

  def mark_failed!(message)
    update!(status: :failed, retries: retries + 1, last_error: message)
  end

  def mark_retry_exhausted!(message)
    update!(status: :retry_exhausted, retries: retries + 1, last_error: message)
  end
end
