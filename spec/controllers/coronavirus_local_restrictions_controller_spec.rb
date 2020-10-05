require "spec_helper"

RSpec.describe CoronavirusLocalRestrictionsController, type: :controller do
  it "correctly renders the local restrictions page" do
    get :show
    expect(response.status).to eq(200)
    expect(response).to render_template("coronavirus_local_restrictions/show")
  end
end
