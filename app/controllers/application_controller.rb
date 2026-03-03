class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_authentication
  helper_method :current_user, :asset_present?

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    return if authenticated?

    redirect_to login_path, alert: "Inicia sesión con tu correo @fintoc.com"
  end

  def asset_present?(logical_name)
    return true unless Rails.env.test?

    begin
      Rails.application.assets_manifest&.assets&.key?(logical_name)
    rescue StandardError
      false
    end
  end
end
