class ChecklistController < ApplicationController
  layout "finder_layout"

  def show
    return redirect_to_result_page if redirect_to_results?

    @checklist_questions = ChecklistQuestionsPresenter.new(page, filtered_params, questions)
    return redirect_to_next_question if redirect_to_next_question?

    render "checklist/show"
  end

  def results
    actions = Checklists::Action.all
    @checklist = Checklists::Answers.new(request.query_parameters.except(:page), actions)
    render "checklist/results"
  end

private

  def qa_config
    @qa_config ||= YAML.load_file("lib/find_brexit_guidance.yaml")
  end

  ###
  # Redirect
  ###

  def redirect_to_next_question?
    @checklist_questions.get_next_page != page
  end

  def redirect_to_next_question
    redirect_to find_brexit_guidance_path(filtered_params.merge(
                                            page: @checklist_questions.get_next_page
                                          ))
  end

  def redirect_to_results?
    page == questions.length + 1
  end

  def redirect_to_result_page
    redirect_to find_brexit_guidance_results_path(filtered_params)
  end

  ###
  # Filtered params
  ###

  def filtered_params
    request.query_parameters.except(:page)
  end
  helper_method :filtered_params

  ###
  # Page title and breadcrumbs
  ###

  def title
    qa_config["title"]
  end
  helper_method :title

  def breadcrumbs
    [{ title: "Home", url: "/" }]
  end
  helper_method :breadcrumbs

  ###
  # Questions
  ###

  def questions
    @questions ||= begin
      qa_config["questions"].map do |question|
        Checklists::Question.new(question)
      end
    end
  end

  ###
  # Current page
  ###

  def page
    @page ||= begin
      params.permit(:page)
      params[:page].to_i.clamp(1, questions.length + 1)
    end
  end

  ###
  # Navigation
  ###
  def next_page
    page + 1
  end
  helper_method :next_page

  def skip_link_url
    page_number = { page: next_page }
    find_brexit_guidance_path(filtered_params.merge(page_number))
  end
  helper_method :skip_link_url
end
