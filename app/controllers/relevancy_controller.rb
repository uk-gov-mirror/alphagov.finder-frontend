class RelevancyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @judgement_set = JudgementSet.new(query: query, organisation: organisation)
    @judgement_set.scores.build(score_attributes)
    if @judgement_set.save
      session[:orgName] = organisation
      session[:first_view] = "false"
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
      filter_params[:scores].each_with_object([]) do |(link_with_index, judgement), scores|
        attrs = link_with_index.split(/(?<=\d)-/)
        index = attrs[0]
        link = attrs[1]
        scores << { link: link, judgement: judgement, link_position: index }
      end
    end
  end
end
