# frozen_string_literal: true

module AccountConcern
  extend ActiveSupport::Concern

  ACCOUNT_SESSION_REQUEST_HEADER_NAME = "HTTP_GOVUK_ACCOUNT_SESSION"
  ACCOUNT_SESSION_RESPONSE_HEADER_NAME = "GOVUK-Account-Session"
  ACCOUNT_END_SESSION_RESPONSE_HEADER_NAME = "GOVUK-Account-End-Session"
  ACCOUNT_SESSION_DEV_COOKIE_NAME = "govuk_account_session"

  ATTRIBUTE_NAME = "transition_checker_state"

  included do
    before_action :fetch_account_session_header
    before_action :set_account_session_header
    before_action :set_account_variant
    # this is a false positive which will be fixed by updating rubocop
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :pre_results, only: %i[results]
    before_action :pre_saved_results, only: %i[saved_results edit_saved_results]
    before_action :pre_update_results, only: %i[save_results_confirm save_results_apply]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    helper_method :logged_in?

    attr_accessor :account_session_header
  end

  def logged_in?
    account_session_header.present?
  end

  def fetch_account_session_header
    @account_session_header =
      if request.headers[ACCOUNT_SESSION_REQUEST_HEADER_NAME]
        request.headers[ACCOUNT_SESSION_REQUEST_HEADER_NAME]
      elsif Rails.env.development?
        cookies[ACCOUNT_SESSION_DEV_COOKIE_NAME]
      end
  end

  def show_signed_in_header?
    account_session_header.present?
  end

  def set_account_variant
    response.headers["Vary"] = [response.headers["Vary"], ACCOUNT_SESSION_RESPONSE_HEADER_NAME].compact.join(", ")

    set_slimmer_headers(
      remove_search: true,
      show_accounts: show_signed_in_header? ? "signed-in" : "signed-out",
    )
  end

  def set_account_session_header(govuk_account_session = nil)
    @account_session_header = govuk_account_session if govuk_account_session
    response.headers[ACCOUNT_SESSION_RESPONSE_HEADER_NAME] = @account_session_header

    if Rails.env.development?
      cookies[ACCOUNT_SESSION_DEV_COOKIE_NAME] = {
        value: @account_session_header,
        domain: "dev.gov.uk",
      }
    end
  end

  def logout!
    response.headers[ACCOUNT_END_SESSION_RESPONSE_HEADER_NAME] = "1"
    @account_session_header = nil

    if Rails.env.development?
      cookies[ACCOUNT_SESSION_DEV_COOKIE_NAME] = {
        value: "",
        domain: "dev.gov.uk",
        expires: 1.second.ago,
      }
    end
  end

  def pre_results
    results_in_account = fetch_results_from_account_or_logout
    return unless logged_in?

    now = Time.zone.now.to_i
    @results_differ = criteria_keys != results_in_account.fetch("criteria_keys", [])
    @results_saved = !@results_differ && results_in_account.fetch("timestamp", now) >= now - 10
  end

  def pre_saved_results
    results_in_account = fetch_results_from_account_or_logout

    redirect_path = if action_name == "saved_results"
                      transition_checker_saved_results_path
                    elsif action_name == "edit_saved_results"
                      transition_checker_edit_saved_results_path
                    end

    redirect_to logged_out_pre_saved_results_path(redirect_path) and return unless logged_in?

    @saved_results = results_in_account.fetch("criteria_keys", [])
  end

  def pre_update_results
    results_in_account = fetch_results_from_account_or_logout
    redirect_to logged_out_pre_update_results_path and return unless logged_in?

    @saved_results = results_in_account.fetch("criteria_keys", [])
  end

  def logged_out_pre_saved_results_path(path = transition_checker_saved_results_path)
    transition_checker_new_session_url(redirect_path: path, _ga: params[:_ga])
  end

  def logged_out_pre_update_results_path
    transition_checker_new_session_url(redirect_path: transition_checker_save_results_confirm_path(c: criteria_keys), _ga: params[:_ga])
  end

  def fetch_results_from_account_or_logout
    result = do_or_logout { Services.account_api.get_attributes(govuk_account_session: account_session_header, attributes: [ATTRIBUTE_NAME]) }
    result&.dig("values", ATTRIBUTE_NAME) || {}
  end

  def fetch_email_subscription_from_account_or_logout
    result = do_or_logout { Services.account_api.check_for_email_subscription(govuk_account_session: account_session_header) }
    result&.fetch("has_subscription", false)
  end

  def update_email_subscription_in_account_or_logout(slug)
    do_or_logout { Services.account_api.set_email_subscription(govuk_account_session: account_session_header, slug: slug) }
  end

  def update_answers_in_account_or_logout(new_criteria_keys)
    do_or_logout { Services.account_api.set_attributes(govuk_account_session: account_session_header, attributes: { ATTRIBUTE_NAME => { criteria_keys: new_criteria_keys, timestamp: Time.zone.now.to_i } }) }
  end

  def do_or_logout
    return unless account_session_header

    result = yield.to_h
    set_account_session_header(result["govuk_account_session"])
    result
  rescue GdsApi::HTTPUnauthorized
    logout!
    nil
  end

  def transition_checker_new_session_url(**params)
    "#{base_path}/sign-in?#{params.compact.to_query}"
  end

  def transition_checker_end_session_url(**params)
    "#{base_path}/sign-out?#{params.compact.to_query}"
  end

  def base_path
    Rails.env.production? ? Plek.new.website_root : Plek.find("frontend")
  end
end
