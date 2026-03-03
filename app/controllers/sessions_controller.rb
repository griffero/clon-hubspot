class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  def new; end

  def create
    email = params[:email].to_s.strip.downcase

    unless email.ends_with?("@fintoc.com")
      redirect_to login_path, alert: "Solo correos @fintoc.com pueden iniciar sesión"
      return
    end

    user = User.find_or_create_by!(email: email)
    raw_token, magic_link = MagicLinkToken.issue_for!(user)

    ResendMagicLinkSender.call(
      to: user.email,
      magic_link_url: magic_link_url(token: raw_token),
      expires_at: magic_link.expires_at
    )

    redirect_to login_path, notice: "Te mandamos un magic link a #{user.email}"
  rescue ResendMagicLinkSender::DeliveryError => e
    Rails.logger.error("[auth] resend delivery failed: #{e.message}")
    redirect_to login_path, alert: "No pudimos enviar el correo. Intenta de nuevo."
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada"
  end
end
