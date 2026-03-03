require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  test "rejects non-fintoc domain" do
    post login_path, params: { email: "x@gmail.com" }

    assert_redirected_to login_path
    follow_redirect!
    assert_match(/Solo correos @fintoc.com/, response.body)
  end

  test "creates magic link and logs in with valid token" do
    original_call = ResendMagicLinkSender.method(:call)
    ResendMagicLinkSender.define_singleton_method(:call) { |**_args| true }

    post login_path, params: { email: "test@fintoc.com" }

    user = User.find_by!(email: "test@fintoc.com")
    token_record = user.magic_link_tokens.order(created_at: :desc).first
    assert token_record.present?

    raw = SecureRandom.urlsafe_base64(32)
    # replace digest to have a deterministic token for this test
    token_record.update!(token_digest: MagicLinkToken.digest(raw))

    get magic_link_path(token: raw)

    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
    assert_includes response.body, "test@fintoc.com"
  ensure
    ResendMagicLinkSender.define_singleton_method(:call, original_call)
  end
end
