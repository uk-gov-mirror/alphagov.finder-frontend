class CoronavirusLocalRestrictionsController < ApplicationController
  layout "development_layout"

  def error_404
    error_not_found
  end
end
