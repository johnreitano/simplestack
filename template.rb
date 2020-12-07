require 'byebug'

def windows?
  require 'rbconfig'
  RbConfig::CONFIG['host_os'].to_s.match?(/mswin|msys|mingw|cygwin|bccwin|wince|emc/)
end

def add_rubocop_config
  copy_file 'rubocop.yml', '.rubocop.yml'
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

  # get rid of annoying tzinfo-data warning
  gsub_file 'Gemfile', %r{.*Windows.*\n.*tzinfo.*\n *\n}, '' unless windows?
end

def update_javascript_files
  code = <<-DONE
  environment.plugins.append('Provide',
    new ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      Popper: ['popper.js', 'default']
    })
  )
  
  DONE
  insert_into_file 'config/webpack/environment.js', code, before: "module.exports = environment"
  
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
// @import '~bootstrap/scss/bootstrap';
DONE
end

def add_sidekiq_config
  insert_into_file "config/routes.rb", "require 'sidekiq/web'\n\n", before: "Rails.application.routes.draw do"
  code = <<-DONE
  mount Sidekiq::Web => '/sidekiq'
    
  DONE
  insert_into_file "config/routes.rb", "#{code}\n", after: "Rails.application.routes.draw do\n"
  environment "config.active_job.queue_adapter = :sidekiq"
end

def update_miscellaneous_config_files
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

  gsub_file 'config/cable.yml', /development:\n *adapter: async/, "development:\n  adapter: <%= ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' } %>"
end

def update_controllers_and_views
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

  insert_into_file 'app/controllers/pages_controller.rb', "    render params[:page_name] || 'home'\n", after: "def show\n"
  create_file 'app/views/pages/home.html.erb', <<-DONE
  <div class="text-center" data-controller="PageController">
    <h2>You have clicked the button <span id="counter"><%= @count %></span> times.</h2>
  </div>
  DONE
end

source_paths.unshift(File.dirname(__FILE__)) # only needed if we want to override app generator templates
add_gems
run 'bundle install'

after_bundle do
  run 'yarn add bootstrap jquery popper.js'
  rails_command 'stimulus_reflex:install'
  generate 'stimulus_reflex TodoItem'
  generate 'controller pages show'
  update_javascript_files
  add_scss_resources
  add_sidekiq_config
  update_controllers_and_views
  update_miscellaneous_config_files
  add_rubocop_config  
  route "get 'pages/:page_name', to: 'pages#show'"
  route "root to: 'pages#show'"
end
