# frozen_string_literal: true

module AccountConcern
  extend ActiveSupport::Concern

  ACCOUNT_SESSION_COOKIE_NAME = :"_finder-frontend_account_session"

  ACCOUNT_SESSION_HEADER_NAME = "GOVUK-Account-Session"
  ACCOUNT_END_SESSION_HEADER_NAME = "GOVUK-Account-End-Session"
  ACCOUNT_SESSION_DEV_COOKIE_NAME = "govuk_account_session"

  ACCOUNT_AB_CUSTOM_DIMENSION = 42
  ACCOUNT_AB_TEST_NAME = "AccountExperiment"

  included do
    before_action :fetch_account_session_header, if: :accounts_enabled?
    before_action :set_account_session_cookie, if: :accounts_enabled?
    before_action :set_account_variant, if: :accounts_enabled?

    helper_method :accounts_available?,
                  :accounts_enabled?,
                  :account_variant,
                  :logged_in?

    attr_accessor :account_session_header
  end

  def accounts_enabled?
    Rails.configuration.feature_flag_govuk_accounts
  end

  def accounts_available?
    return false unless accounts_enabled?

    if @check_accounts_available.nil?
      @check_accounts_available = true
      begin
        RestClient.get(Services.accounts_api)
      rescue RestClient::ServiceUnavailable
        @check_accounts_available = false
      rescue StandardError
        # Currently we're only guarding against planned 503 errors
        # In future we may want to selectively disable accounts if
        # a 5xx error rate gets too high, but that needs some more
        # thought first.
        @check_accounts_available = true
      end
    end
    @check_accounts_available
  end

  def logged_in?
    account_session_header_value&.dig(:access_token).present?
  end

  def handle_disabled
    render status: :not_found, plain: "404 error not found"
  end

  def handle_offline
    redirect_to Services.accounts_api
  end

  def fetch_account_session_header
    @account_session_header =
      if request.headers[ACCOUNT_SESSION_HEADER_NAME]
        request.headers[ACCOUNT_SESSION_HEADER_NAME]
      elsif Rails.env.development?
        cookies[ACCOUNT_SESSION_DEV_COOKIE_NAME]
      elsif cookies.encrypted[ACCOUNT_SESSION_COOKIE_NAME]
        legacy_cookie = JSON.parse(cookies.encrypted[ACCOUNT_SESSION_COOKIE_NAME])
        cookie_value = encode_account_session_header(legacy_cookie["access_token"], legacy_cookie["refresh_token"])
        response.headers[ACCOUNT_SESSION_HEADER_NAME] = cookie_value
        cookie_value
      end
  end

  def account_session_header_value
    bits = (account_session_header || "").split(".")
    if bits.length == 2
      {
        access_token: Base64.urlsafe_decode64(bits[0]),
        refresh_token: Base64.urlsafe_decode64(bits[1]),
      }
    end
  end

  def encode_account_session_header(access_token, refresh_token)
    "#{Base64.urlsafe_encode64(access_token)}.#{Base64.urlsafe_encode64(refresh_token)}"
  end

  def account_variant
    @account_variant ||= begin
      ab_test = GovukAbTesting::AbTest.new(
        ACCOUNT_AB_TEST_NAME,
        dimension: ACCOUNT_AB_CUSTOM_DIMENSION,
        allowed_variants: %w[LoggedIn LoggedOut],
        control_variant: "LoggedOut",
      )
      ab_test.requested_variant(request.headers)
    end
  end

  def show_signed_in_header?
    account_session_header.present? || account_variant.variant?("LoggedIn")
  end

  def set_account_variant
    account_variant.configure_response(response)
    response.headers["Vary"] = [response.headers["Vary"], ACCOUNT_SESSION_HEADER_NAME].compact.join(", ")

    set_slimmer_headers(
      remove_search: true,
      show_accounts: show_signed_in_header? ? "signed-in" : "signed-out",
    )
  end

  def set_account_session_cookie(access_token: nil, refresh_token: nil)
    new_access_token = access_token || account_session_header_value&.dig(:access_token)
    new_refresh_token = refresh_token || account_session_header_value&.dig(:refresh_token)

    return if new_access_token.nil? || new_refresh_token.nil?

    cookies.encrypted[ACCOUNT_SESSION_COOKIE_NAME] = {
      value: {
        access_token: new_access_token,
        refresh_token: new_refresh_token,
      }.to_json,
      expires: 15.minutes,
      secure: Rails.env.production?,
    }

    @account_session_header = encode_account_session_header(new_access_token, new_refresh_token)
    response.headers[ACCOUNT_SESSION_HEADER_NAME] = @account_session_header

    if Rails.env.development?
      cookies[ACCOUNT_SESSION_DEV_COOKIE_NAME] = {
        value: @account_session_header,
        domain: "dev.gov.uk",
      }
    end
  end

  def update_account_session_cookie_from_oauth_result(result)
    set_account_session_cookie(
      access_token: result[:access_token],
      refresh_token: result[:refresh_token],
    )
    result[:result]
  end

  def logout!
    cookies.delete ACCOUNT_SESSION_COOKIE_NAME
    response.headers[ACCOUNT_END_SESSION_HEADER_NAME] = "1"
    @account_session_header = nil
  end
end
