class RelevancyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @judgement_set = JudgementSet.new(query: query, organisation: organisation)
    @judgement_set.scores.build(score_attributes)
    if @judgement_set.save
      redirect_to search_path,
                  notice: "saved"
    else
      redirect_to "/search/all?keywords=#{params['query']}",
                  alert: "alert"
    end
  end

private

  def query
    filter_params["query"]
  end

  def organisation
    filter_params["org-name"]
  end

  def score_attributes
    if filter_params[:scores]
      filter_params[:scores].each_with_object([]) do |(link, judgement), scores|
        m = link.match(/(?<index>^\d+)-(?<link>\/.+)/)
        scores << { link: m[:link], judgement: judgement, link_position: m[:index] }
      end
    end
  end
end
