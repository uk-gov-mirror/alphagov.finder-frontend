require "spec_helper"

describe Score do
  let(:judgement) { double("judgement") }
  let(:params) { { link: "govuk/nhs-spending", judgement: "perfect", link_position: 0 } }

  it "#judgement" do
    expect(Score.new(params).judgement).to eq "3"
  end
end
