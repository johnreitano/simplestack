class TodoItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item, only: [:destroy]

  def index
    prepare_variables_and_render_index_template
  end

  def create
    @todo_item = TodoItem.new(todo_item_params)
    if @todo_item.save
      redirect_to todo_items_path, notice: 'Todo item was successfully created.'
    else
      prepare_variables_and_render_index_template
    end
  end

  def destroy
    @todo_item.destroy
    prepare_variables_and_render_index_template
  end

  private

  def set_todo_list
    @todo_list = TodoList.first_or_create!
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:id])
  end

  def todo_item_params
    params.require(:todo_item).permit(:description, :completed_at)
  end

  def prepare_variables_and_render_index_template
    @todo_items = @todo_list.todo_items
    @todo_item = TodoItem.new
    render :index
  end
end
