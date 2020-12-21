def installing_on_windows?
  require 'rbconfig'
  RbConfig::CONFIG['host_os'].to_s.match?(/mswin|msys|mingw|cygwin|bccwin|wince|emc/)
end

def update_gems
  # get rid of annoying tzinfo-data warning when not installing on windows
  gsub_file 'Gemfile', /.*Windows.*\n.*tzinfo.*\n *\n/, '' unless installing_on_windows?

  # remove sqlite3
  gsub_file 'Gemfile', /.*gem 'sqlite3'.*\n/, ''

  gem 'redis'
  gem 'hiredis'
  gem 'bootstrap'
  gem 'font-awesome-rails'
  gem 'stimulus_reflex', '3.3.0'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'
  gem 'pg'

  gem_group :development, :test do
    gem 'rubocop', require: false
  end
end

def add_home_page
  generate 'controller pages home --no-stylesheets --no-helper'
  route "root to: 'pages#home'"
  remove_file 'app/views/pages/home.html.erb'
  create_file 'app/views/pages/home.html.erb', <<-'DONE'
  <h1>Welcome to <%= Rails.application.class.parent_name %></h1>

  <p>This application was built using <%= link_to 'Simple Stack', 'https://github.com/johnreitano/simple-stack' %>.</p>
  <p>Here is <%= link_to "an example of Simple Stack in action", todo_items_path %>.
  DONE
end

def add_todo_example
  puts "cp -R #{__dir__}/todo_example_src/* ./"
  run "cp -R #{__dir__}/todo_example_src/* ./"
  route "resources :todo_items"
end

def update_javascript_resources
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
  insert_into_file 'config/webpack/environment.js', code, after: "const { environment } = require('@rails/webpacker')\n"
  
  remove_file 'app/javascript/packs/application.js'
  create_file 'app/javascript/packs/application.js', <<-DONE
  require('@rails/ujs').start();
  require('turbolinks').start();
  require('@rails/activestorage').start();
  require('channels');

  require('bootstrap');
  require('controllers');
  require('@fortawesome/fontawesome-free/js/all') // TODO: move font-awesome to example step

  require('../scss/global.scss') // TODO: make these two consistent
  require('images') // TODO: make these two consistent, one is wrong
  DONE
end

def add_scss_resources
  create_file 'app/javascript/scss/global.scss', <<-'DONE'
    @import '~bootstrap/scss/bootstrap';
  DONE
end

def add_image_resources
  create_file 'app/javascript/images/index.js', <<-'DONE'
  const images = require.context('../images', true)
  const imagePath = (name) => images(name, true)
  DONE
end

def update_application_layout
  gsub_file 'app/views/layouts/application.html.erb', /_link_tag/, '_pack_tag' 
  gsub_file 'app/views/layouts/application.html.erb', / *<body .*> *(\n.*)* *<\/body>/, <<-'DONE'
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
  run 'cat app/views/layouts/application.html.erb'
end

def install_and_configure_stimulus
  run 'rails dev:cache'
  rails_command 'stimulus_reflex:install'
  insert_into_file "app/reflexes/application_reflex.rb", "  delegate :render, to: ApplicationController\n", before: "end"
  code = <<-'DONE'
    this.startTime = performance.now()
  DONE
  insert_into_file "app/javascript/controllers/application_controller.js", "#{code}\n", after: /beforeReflex.*\n/

  code = <<-'DONE'
    this.endTime = performance.now()
    this.elapsedTime = this.endTime - this.startTime
    console.log('round-trip time for reflex: ', this.elapsedTime)
  DONE
  insert_into_file "app/javascript/controllers/application_controller.js", "#{code}\n", after: /afterReflex.*\n/
end

def create_and_migrate_db
  rails_command 'db:create'
  rails_command 'db:migrate'
end

def install_node_packages
  run 'yarn add bootstrap jquery popper.js npm install @fortawesome/fontawesome-free stimulus_reflex@3.3.0' # TODO: move font-awesome to example step
end

def configure_action_cable
  # TODO: check if this is still necessary
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
  copy_file "#{__dir__}/rubocop.yml", '.rubocop.yml'
end

def configure_sidekiq
  insert_into_file "config/routes.rb", "require 'sidekiq/web'\n\n", before: "Rails.application.routes.draw do"
  code = <<-DONE
  mount Sidekiq::Web => '/sidekiq'

  DONE
  insert_into_file "config/routes.rb", "#{code}\n", after: "Rails.application.routes.draw do\n"
  environment "config.active_job.queue_adapter = :sidekiq"
end
update_gems
run 'bundle install'
after_bundle do
  install_node_packages
  add_home_page
  add_todo_example
  install_and_configure_stimulus
  update_javascript_resources
  add_scss_resources
  add_image_resources
  update_application_layout
  configure_action_cable
  configure_redis_cache
  configure_rubocop  
  configure_sidekiq
  create_and_migrate_db
end
