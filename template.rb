def installing_on_windows?
  require 'rbconfig'
  RbConfig::CONFIG['host_os'].to_s.match?(/mswin|msys|mingw|cygwin|bccwin|wince|emc/)
end

def add_gems
  gem 'redis'
  gem 'hiredis'
  gem 'bootstrap'
  gem 'font-awesome-rails'
  gem 'stimulus_reflex', '3.3.0'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'

  gem_group :development, :test do
    gem 'rubocop', require: false
  end

  # get rid of annoying tzinfo-data warning when not installing on windows
  gsub_file 'Gemfile', %r{.*Windows.*\n.*tzinfo.*\n *\n}, '' unless installing_on_windows?
end

def scaffold_todo_item
  # run 'bundle exec rails generate scaffold TodoItem description:text completed_at:datetime'
  generate :model, 'TodoItem description:text completed_at:datetime --no-jbuilder'
  remove_file "app/models/todo_item.rb"
  create_file "app/models/todo_item.rb", <<-DONE
class TodoItem < ApplicationRecord
  scope :completed, -> { where.not(completed_at: nil) }

  def self.percent_complete
    if total_items_count.zero?
      0.0
    else
      (100 * completed_items_count.to_f / total_items_count).round(1)
    end
  end

  def self.total_items_count
    TodoItem.count
  end

  def self.completed_items_count
    TodoItem.completed.count
  end

  def self.list_status
    case percent_complete.to_i
    when 0
      'Not started'
    when 100
      'Completed'
    else
      'In Progress'
    end
  end

  def self.badge_color
    case percent_complete.to_i
    when 0
      'dark'
    when 100
      'info'
    else
      'primary'
    end
  end

  def completed?
    completed_at.present?
  end
end
DONE
  
  generate :scaffold, 'TodoItem --no-stylesheets --skip-template-engine'
  remove_file "app/controllers/todo_items_controller.rb"
  create_file "app/controllers/todo_items_controller.rb", <<-DONE
class TodoItemsController < ApplicationController
  before_action :set_todo_item, only: [:update, :destroy]

  def index
    prepare_variables_and_render_index_template
  end

  def create
    @todo_item = TodoItem.new(todo_item_params)
    if @todo_item.save
      # render :nothing
      redirect_to todo_items_path, notice: 'Todo item was successfully created.'
    else
      prepare_variables_and_render_index_template
    end
  end

  def update
    if @todo_item.update(todo_item_params)
      redirect_to todo_items_path, notice: 'Todo item was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @todo_item.destroy
    redirect_to todo_items_path, notice: 'Todo item was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_todo_item
    @todo_item = TodoItem.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def todo_item_params
    params.require(:todo_item).permit(:description, :completed, :completed_at)
  end

  def prepare_variables_and_render_index_template
    @todo_items = TodoItem.all
    @todo_item = TodoItem.new
    render :index
  end
end
DONE

run "rm -f app/views/todo_items/*"
create_file "app/views/todo_items/index.html.erb", <<-DONE
<div class="card-header d-flex justify-content-between">
  <div class="row">
    <div class="col-10 d-flex justify-content-between">
      <div>
        <h5 class="m-0">
          <b>Todos</b>
          <span class="badge badge-<%= TodoItem.badge_color %>"><%= TodoItem.list_status %></span>
        </h5>
        <p class="text-secondary m-0"><%= TodoItem.percent_complete %>% (<%= TodoItem.completed_items_count %>/<%= TodoItem.total_items_count %> Todo Items)</p>
      </div>
    </div>
  </div>
</div>
<div class="card-body">
  <div class="progress mb-4">
    <div class="progress-bar bg-info" role="progressbar" style="width: <%= TodoItem.percent_complete %>%" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"></div>
  </div>
  <%= form_for([@todo_item]) do |f| %>
    <div class="input-group mb-4">
      <%= f.text_field :description, class: "form-control", placeholder: "Add a todo item" %>
      <div class="input-group-append">
        <%= f.submit "Add", class: "btn btn-primary input-group-btn" %>
      </div>
    </div>
  <% end %>
  <ul class="list-group">
    <% @todo_items.each do |todo_item| %>
      <li class="list-group-item <%= 'bg-light' if todo_item.completed? %>%">
        <div class="d-flex justify-content-between ">
          <span>
            <em><%= todo_item.description %></em>
          </span>
          <%= link_to "#", class: 'btn btn-info', data: { reflex: 'click->TodoItem#toggle', id: todo_item.id } do %>
            <%= render partial: 'todo_items/completed_icon', locals: { todo_item: todo_item } %>
          <% end %>
        </div>
      </li>
    <% end %>
  </ul>
</div>
DONE

create_file "app/views/todo_items/_completed_icon.html.erb", <<-DONE
<span id="icon-wrapper">
  <i class="fas <%= todo_item.completed? ? 'fa-check-square' : 'fa-square' %>"></i>
</span>
DONE

  route "root to: 'todo_items#index'"
  route "resources :todo_items"
end

def update_javascript_files
  code = <<-DONE

const { ProvidePlugin } = require('webpack')
environment.plugins.append('Provide',
  new ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['popper.js', 'default']
  })
)
DONE
  insert_into_file 'config/webpack/environment.js', code, after: "const { environment } = require('@rails/webpacker')"
  
  create_file 'app/javascript/images/index.js', <<-DONE
  const images = require.context('../images', true)
  const imagePath = (name) => images(name, true)
  DONE

  remove_file 'app/javascript/packs/application.js'
  create_file 'app/javascript/packs/application.js', <<-DONE
  import 'bootstrap';
  require('bootstrap/scss/bootstrap.scss');
  import "@fortawesome/fontawesome-free/js/all"
  import '../scss/global.scss'
  require('@rails/ujs').start();
  require('turbolinks').start();
  require('@rails/activestorage').start();
  require('controllers');
  require('channels');
  require("images")
  DONE

end

def add_scss_resources
  create_file 'app/javascript/scss/global.scss', <<DONE
// @import '~bootstrap/scss/bootstrap'; // TODO: cut this?
DONE
end

def update_application_layout
  gsub_file 'app/views/layouts/application.html.erb', /_link_tag/, '_pack_tag' 
  gsub_file 'app/views/layouts/application.html.erb', %r{ *<body .*> *(\n.*)* *</body>}, <<-DONE
    <body class="bg-light">
      <div class="container">
        <div class="row">
          <div class="col-md-10 col-lg-8 offset-md-1 offset-lg-2">
            <p id="notice"><%= notice %></p>
            <div class="card mt-5">
              <%= yield %>
            </div>
          </div>
        </div>
      </div>
    </body>
  DONE
end

def install_and_configure_stimulus
  run 'rails dev:cache'
  rails_command 'stimulus_reflex:install'
  generate :stimulus_reflex, 'TodoItem toggle'  
  gsub_file 'app/reflexes/todo_item_reflex.rb', %r{def toggle\n *end}, <<-'DONE'
  rescue_from Exception do |e|
    cable_ready.console_log(message: "got error: #{e.message}").broadcast
    morph(:nothing)
  end

  def toggle
    todo_item = TodoItem.find(element.dataset.id)
    todo_item.update(completed_at: todo_item.completed? ? nil : Time.now)
  end
DONE
end

def migrate_db
  rails_command 'db:migrate'
end

def install_node_packages
  run 'yarn add bootstrap jquery popper.js npm install @fortawesome/fontawesome-free stimulus_reflex@3.3.0'
end

def configure_action_cable
  gsub_file 'config/cable.yml', /development:\n *adapter: async/, "development:\n  adapter: <%= ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' } %>"
end

def configure_redis_cache
  environment "config.cache_store = :redis_cache_store, { driver: :hiredis, url: ENV.fetch('REDIS_URL') }", env: 'production'
  
  code = <<-DONE
  config.session_store :redis_session_store, {
    key: Rails.application.credentials.app_session_key,
    serializer: :json,
    redis: {
      expire_after: 1.year,
      ttl: 1.year,
      key_prefix: 'app:session:',
      url: ENV.fetch('REDIS_URL')
    }    
  DONE
  environment code, env: 'production'
end

def configure_rubocop
  copy_file 'rubocop.yml', '.rubocop.yml'
end

def configure_sidekiq
  insert_into_file "config/routes.rb", "require 'sidekiq/web'\n\n", before: "Rails.application.routes.draw do"
  code = <<-DONE
  mount Sidekiq::Web => '/sidekiq'

  DONE
  insert_into_file "config/routes.rb", "#{code}\n", after: "Rails.application.routes.draw do\n"
  environment "config.active_job.queue_adapter = :sidekiq"
end

add_gems
run 'bundle install'
after_bundle do
  install_node_packages
  scaffold_todo_item
  install_and_configure_stimulus
  migrate_db
  update_javascript_files
  add_scss_resources
  update_application_layout
  configure_action_cable
  configure_redis_cache
  configure_rubocop  
  configure_sidekiq
end
