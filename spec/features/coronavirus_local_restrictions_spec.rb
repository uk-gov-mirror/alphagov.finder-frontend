require "spec_helper"

RSpec.feature "Coronavirus local restrictions lookup", type: :feature do
  scenario "User visits postcode lookup page" do
    given_i_am_on_the_local_restrictions_page
    then_i_can_see_the_postcode_lookup
  end

  def given_i_am_on_the_local_restrictions_page
    visit find_coronavirus_local_restrictions_path
  end

  def then_i_can_see_the_postcode_lookup
    expect(page).to have_content(I18n.t("coronavirus_local_restrictions.lookup.title"))
  end
end
