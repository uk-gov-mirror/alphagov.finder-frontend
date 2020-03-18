FinderFrontend::Application.routes.draw do
  # https://github.com/alphagov/govuk-search-relevance-tool
  new_site = "https://govuk-search-relevance-tool.cloudapps.digital/"
  root to: redirect(new_site)
  get "*path" => redirect(new_site)
end
