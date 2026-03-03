class ExportTable < ApplicationRecord
  belongs_to :export_run

  enum :status, {
    pending: 0,
    written: 1,
    verified: 2,
    mismatch: 3
  }, validate: true

  validates :extractor_key, :object_type, :file_path, presence: true
end
