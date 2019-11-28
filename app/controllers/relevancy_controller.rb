class RelevancyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @judgement_set = JudgementSet.new(query: query, organisation: organisation)
    @scores = scores(@judgement_set)
    if @judgement_set.save && @judgement_set.scores.any?
      redirect_to search_path,
                  notice: "<h2>Thank you</h2><p>Your scores have been saved. You can perform another search to score more results.</p>"
    else
      redirect_to search_path,
                  alert: "<h2>There has been an error</h2><p>Please perform another search to score the results.</p>"
    end
  end

private

  def query
    filter_params["query"]
  end

  def organisation
    filter_params["org-name"]
  end

  def scores(judgement_set)
    if filter_params[:scores]
      filter_params[:scores].each do |link, judgement|
        m = link.match(/(?<index>^\d+)-(?<link>\/.+)/)
        Score.create(link: m[:link],
                      judgement: judgement,
                      judgement_set: judgement_set,
                      link_position: m[:index])
      end
    end
  end
end
