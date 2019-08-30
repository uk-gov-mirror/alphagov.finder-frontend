require "spec_helper"
require "checklists/convert_csv_to_yaml/converter"

describe Checklists::ConvertCsvToYaml::Converter do
  include FixturesHelper
  let(:csv_file_path) { actions_csv_to_convert_to_yaml }
  let(:yaml_file_path) { Tempfile.new("a_file.yaml").path }
  let(:processor) { double("processor") }

  describe "#convert" do
    let(:loaded_yaml_file) { YAML.safe_load(File.read(yaml_file_path)) }

    before do
      allow(processor).to receive(:process)
                      .and_return("title_url" => "https://www.gov.uk/important-action")
    end

    it "converts CSV file data to YAML and writes to a YAML file" do
      converter = Checklists::ConvertCsvToYaml::Converter.new(processor)
      converter.convert(csv_file_path, yaml_file_path)

      expect(loaded_yaml_file).to include(
        "title_url" => "https://www.gov.uk/important-action"
      )
    end

    it "allows an optional record category to be set as a key in the YAML file" do
      converter = Checklists::ConvertCsvToYaml::Converter.new(processor)
      converter.convert(csv_file_path, yaml_file_path, "category")

      expect(loaded_yaml_file).to eq(
        "category" => [
          { "title_url" => "https://www.gov.uk/important-action" }
        ]
      )
    end
  end
end