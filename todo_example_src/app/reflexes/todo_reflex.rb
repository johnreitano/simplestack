# frozen_string_literal: true

class TodoReflex < ApplicationReflex
  # Add Reflex methods in this file.
  #
  # All Reflex instances expose the following properties:
  #
  #   - connection - the ActionCable connection
  #   - channel - the ActionCable channel
  #   - request - an ActionDispatch::Request proxy for the socket connection
  #   - session - the ActionDispatch::Session store for the current visitor
  #   - url - the URL of the page that triggered the reflex
  #   - element - a Hash like object that represents the HTML element that triggered the reflex
  #   - params - parameters from the element's closest form (if any)
  #
  # Example:
  #
  #   def example(argument=true)
  #     # Your logic here...
  #     # Any declared instance variables will be made available to the Rails controller and view.
  #   end
  #
  # Learn more at: https://docs.stimulusreflex.com

  before_reflex :set_todo_list
  before_reflex :set_todo_item, only: [:toggle_completed, :destroy]

  rescue_from Exception do |_e|
    byebug
    morph :nothing
  end

  def create
    todo_item_params = params.require(:todo_item).permit(:id, :description)
    todo_item = @todo_list.todo_items.create!(todo_item_params)
  end

  def toggle_completed
    @todo_item.update(completed_at: @todo_item.completed? ? nil : Time.now)
  end

  def destroy
    @todo_item.destroy
  end

  def postpone
    @todo_list.postpone!
    html = render(partial: 'todo_items/deadline', locals: { todo_list: @todo_list })
    morph "#deadline-wrapper", html
  end

  private

  def set_todo_list
    @todo_list = TodoList.first_or_create!
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(element.dataset.id)
  end

end
