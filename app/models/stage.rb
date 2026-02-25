class Stage < ApplicationRecord
  belongs_to :pipeline
  has_many :deals, dependent: :nullify

  scope :ordered, -> { order(:display_order) }
  scope :open, -> { where(is_closed: false) }

  def total_deal_value
    deals.sum(:amount)
  end
end
