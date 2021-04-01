class TodoItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item, except: [:index, :create]

  def index
    prepare_variables_and_render_index_template
  end

  def create
    @todo_item = @todo_list.todo_items.build(todo_item_params)

    respond_to do |format|
      if @todo_item.save
        format.html do
          redirect_to todo_items_path, notice: 'Todo item was successfully created.'
        end
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_item, partial: 'todo_items/form', locals: { todo_item: @todo_item }) }
        format.html { prepare_variables_and_render_index_template }
      end
    end
  end

  def toggle_complete
    @todo_item.toggle_complete!
    redirect_to todo_items_path, notice: "Todo item was #{@todo_item.completed_at ? 'completed' : 'marked incomplete'}."
  end

  def destroy
    @todo_item.destroy!
    redirect_to todo_items_path, notice: 'Todo item was destroyed.'
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
    @todo_items = @todo_list.todo_items.order(created_at: :desc)
    @todo_item = TodoItem.new
    render :index
  end
end
