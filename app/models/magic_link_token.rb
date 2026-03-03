require "digest"
require "securerandom"

class MagicLinkToken < ApplicationRecord
  TTL = 20.minutes

  belongs_to :user

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user)
    raw = SecureRandom.urlsafe_base64(32)
    token = create!(
      user: user,
      token_digest: digest(raw),
      expires_at: Time.current + TTL
    )

    [ raw, token ]
  end

  def self.consume!(raw_token)
    record = active.find_by(token_digest: digest(raw_token))
    return nil if record.blank?

    record.update!(used_at: Time.current)
    record
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end
end
