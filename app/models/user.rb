class User < ApplicationRecord
  has_many :magic_link_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: /\A[^@\s]+@fintoc\.com\z/, message: "must be a @fintoc.com email" }
end
