require "json"

namespace :relevancy do
  desc "fixes truncated links"
  task truncated_link_fixer: :environment do
    Relevance::LinkFixer.new.fix
  end
end
