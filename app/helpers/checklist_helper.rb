module ChecklistHelper
  def next_viewable_page(page, questions, criteria_keys)
    next_page = (page..questions.length).find do |index|
      questions[index - 1].show?(criteria_keys)
    end
    next_page || questions.length + 1
  end

  def format_criteria_list(criteria)
    criteria.map { |criterion| { readable_text: criterion.text } }
  end

  def format_action_sections(actions)
    [
      {
        heading: 'Some category',
        actions: actions
      }
    ]
  end
end
