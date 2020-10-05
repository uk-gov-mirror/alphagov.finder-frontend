require "spec_helper"

RSpec.describe CoronavirusLocalRestrictionsConstraint do
  describe "#matches?" do
    it "returns false when the environment is production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect(described_class.new.matches?).to eq(false)
    end

    it "returns true if the environment is not production" do
      expect(described_class.new.matches?).to eq(true)
    end
  end
end
