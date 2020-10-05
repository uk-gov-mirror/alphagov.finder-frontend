class LocationLookupService
  attr_reader :postcode

  def initialize(postcode)
    @postcode = postcode
  end

  def data
    binding.pry
    location_data = areas.map do |_, area|
      location = MapitPostcodeResponse.new(area)
      location if location.gss
    end

    location_data.compact
  end

private

  def areas
    return [] if response.blank?
    binding.pry
    response["response"].select { |data| data.first == "areas" }.first.last
  end

  def response
    @response ||= begin
                    JSON.parse(GdsApi.mapit.location_for_postcode(postcode).to_json)
                  rescue GdsApi::HTTPNotFound
                    []
                  rescue GdsApi::HTTPClientError => e
                    { error: e }
                  end
  end
end
