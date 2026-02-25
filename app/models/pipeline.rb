class Pipeline < ApplicationRecord
  has_many :stages, -> { order(:display_order) }, dependent: :destroy
  has_many :deals, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order) }

  def total_deal_value
    deals.sum(:amount)
  end
end
