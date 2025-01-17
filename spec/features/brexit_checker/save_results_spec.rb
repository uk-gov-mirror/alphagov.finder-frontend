require "spec_helper"
require "gds_api/test_helpers/account_api"
require "gds_api/test_helpers/email_alert_api"

RSpec.feature "Brexit Checker create GOV.UK Account", type: :feature do
  include GdsApi::TestHelpers::AccountApi
  include GdsApi::TestHelpers::ContentStore
  include GdsApi::TestHelpers::EmailAlertApi

  before do
    stub_account_api_create_registration_state(state_id: "jwt-id")
    stub_account_api_get_sign_in_url(redirect_path: "/transition-check/save-your-results/confirm?c%5B%5D=nationality-eu", state_id: "jwt-id")
    stub_email_subscription_confirmation
  end

  scenario "user clicks Create a GOV.UK account" do
    given_im_on_the_results_page
    then_i_click_to_subscribe
    and_i_am_taken_to_choose_how_to_subscribe_page
    and_i_click_the_create_account_button
    i_get_redirected_to_sign_up
  end

  def given_im_on_the_results_page
    visit transition_checker_results_url(c: %w[nationality-eu])
  end

  def then_i_click_to_subscribe
    click_on "Subscribe"
  end

  def and_i_am_taken_to_choose_how_to_subscribe_page
    expect(page).to have_current_path(transition_checker_save_results_url(c: %w[nationality-eu]))
  end

  def and_i_click_the_create_account_button
    form = page.find("form#account-signup")
    expect(form.text).to eql("Create a GOV.UK account")
    expect(form["method"]).to eql("post")
    click_on I18n.t("brexit_checker.account_signup.create_account.cta_button")
  end

  def i_get_redirected_to_sign_up
    expect(page.current_url).to include("&state_id=jwt-id")
  end

  def stub_email_subscription_confirmation
    stub_email_alert_api_creates_subscriber_list(
      {
        "title" => "Get ready for 2021",
        "slug" => "test-slug",
        "tags" => { "brexit_checklist_criteria" => { "any" => %w[nationality-eu] } },
        "url" => "/transition-check/results?c%5B%5D=nationality-eu",
      },
    )
  end
end
