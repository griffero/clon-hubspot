class MagicLinksController < ApplicationController
  skip_before_action :require_authentication, only: :show

  def show
    token = params[:token].to_s
    magic_link = MagicLinkToken.consume!(token)

    if magic_link.blank?
      redirect_to login_path, alert: "Magic link inválido o expirado"
      return
    end

    session[:user_id] = magic_link.user_id
    redirect_to root_path, notice: "Bienvenido"
  end
end
