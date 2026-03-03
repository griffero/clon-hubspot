class ResendMagicLinkSender
  class DeliveryError < StandardError; end

  RESEND_API_URL = "https://api.resend.com/emails".freeze

  def self.call(to:, magic_link_url:, expires_at:)
    new.call(to:, magic_link_url:, expires_at:)
  end

  def call(to:, magic_link_url:, expires_at:)
    response = connection.post do |req|
      req.url RESEND_API_URL
      req.body = {
        from: from_email,
        to: [to],
        subject: "Tu magic link para Clon Hubspot",
        html: html_body(magic_link_url, expires_at)
      }
    end

    return if response.success?

    raise DeliveryError, "Resend error #{response.status}: #{response.body}"
  rescue Faraday::Error => e
    raise DeliveryError, e.message
  end

  private

  def connection
    @connection ||= Faraday.new do |f|
      f.request :json
      f.response :json, content_type: /json/
      f.headers["Authorization"] = "Bearer #{api_key}"
      f.headers["Content-Type"] = "application/json"
      f.options.timeout = 20
      f.options.open_timeout = 10
    end
  end

  def api_key
    ENV.fetch("RESEND_API_KEY")
  end

  def from_email
    ENV.fetch("RESEND_FROM_EMAIL", "Clon Hubspot <auth@fintoc.com>")
  end

  def html_body(magic_link_url, expires_at)
    <<~HTML
      <p>Hola,</p>
      <p>Haz click para entrar a Clon Hubspot:</p>
      <p><a href="#{magic_link_url}">Entrar con magic link</a></p>
      <p>Este link expira a las #{expires_at&.in_time_zone&.strftime("%H:%M %Z")}.</p>
      <p>Si no lo pediste, ignora este correo.</p>
    HTML
  end
end
