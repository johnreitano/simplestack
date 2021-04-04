require 'byebug'

def installing_on_windows?
  require 'rbconfig'
  RbConfig::CONFIG['host_os'].to_s.match?(/mswin|msys|mingw|cygwin|bccwin|wince|emc/)
end

def update_gems
  say "Installing gems..."

  # get rid of annoying tzinfo-data warning when not installing on windows
  gsub_file 'Gemfile', %r{.*Windows.*\n.*tzinfo.*\n *}, '' unless installing_on_windows?
  
  # remove sqlite3
  gsub_file 'Gemfile', /.*gem 'sqlite3'.*\n/, ''

  gem 'bootstrap'
  gem 'font-awesome-rails'
  gem 'hotwire-rails'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'

  gem_group :development, :test do
    gem 'rubocop', require: false
  end
end

def install_hotwire_and_redis
  rails_command 'hotwire:install'
  gsub_file "Gemfile", /^gem 'redis'/, "# gem 'redis'" # remove redis that was added by hotwire
  gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
  gem 'hiredis'
  gem 'redis-session-store'
  run 'bundle install'
end

def add_home_page
  say "Adding home page..."

  generate 'controller pages home --no-stylesheets --no-helper'
  route "root to: 'pages#home'"
  remove_file 'app/views/pages/home.html.erb'
  create_file 'app/views/pages/home.html.erb', <<-'DONE'
  <div class="p-5">
    <h1>Welcome to <%= Rails.application.class.to_s.split('::').first %></h1>

    <p>This application was generated using <%= link_to 'SimpleStack', 'https://github.com/johnreitano/simplestack' %>.</p>
    <p>Here is <%= link_to "an example of SimpleStack in action", todo_items_path %>.
  </div>
  
  DONE
end

def copy_app_files
  say "Copying app files..."

  run "cp -R ../.simplestack_app_files/* ../.simplestack_app_files/.env.example ./"
  app_name = File.basename(Dir.getwd).underscore
  gsub_file '.env.example', /foo_development/, "#{app_name}_development" 
  run "cp .env.example .env"
end

def add_todo_routes
  say "Adding Todo routes..."

  route <<-DONE
  
  resources :todo_lists, only: [] do\n
    member do
      patch :postpone
    end
  end

  resources :todo_items do
    member do
      patch :toggle_complete
    end
  end
  
  DONE
end

def update_javascript_resources
  say "Updating javascript resources..."

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
  
  code = <<-DONE  
  
  import "jquery";
  import "popper.js";
  import "bootstrap";
  import "@fortawesome/fontawesome-free/css/all";
  DONE
  insert_into_file 'app/javascript/packs/application.js', code, after: "import \"channels\"\n"

  code = <<-DONE  
  
  require("../scss/global.scss");
  require("images");
  DONE
  insert_into_file 'app/javascript/packs/application.js', code, after: "ActiveStorage.start()\n"
end

def add_scss_resources
  say "Adding javascript resources..."

  create_file 'app/javascript/scss/global.scss', <<-'DONE'
  @import '~bootstrap/scss/bootstrap';

  .field_with_errors {
    display: block;
    width: 100%;
  }
  DONE
end

def add_image_resources
  say "Adding image resources..."

  create_file 'app/javascript/images/index.js', <<-'DONE'
  const images = require.context("../images", true);
  const imagePath = (name) => images(name, true);
  DONE
end

def update_application_layout
  say "Updating application layout..."

  gsub_file 'app/views/layouts/application.html.erb', /stylesheet_link_tag/, 'stylesheet_pack_tag' 
  gsub_file 'app/views/layouts/application.html.erb', / *<%= yield %> */, <<-'DONE'
    <body class="bg-light">
      <div class="container">
        <div class="row">
          <div class="col-md-10 col-lg-8 offset-md-1 offset-lg-2">
            <div class="card mt-5">
              <%= yield %>
            </div>
          </div>
        </div>
      </div>
    </body>
  DONE
end

def install_node_packages
  say "Installing node packages..."

  run 'yarn add bootstrap jquery popper.js @fortawesome/fontawesome-free' # TODO: move font-awesome to example step
end

def configure_action_cable
  say "Configuring action cable..."

  gsub_file 'config/cable.yml',
    %r(url: redis://localhost:6379/1\n), 
    %(url: \<\%\= ENV.fetch\("REDIS_URL"\) \%\>\n)

    gsub_file 'config/cable.yml',
      %r( { "redis://localhost:6379/1" }),
      ''
end

def configure_redis_cache
  say "Configuring Redis cache store and session store..."

  environment "config.cache_store = :redis_cache_store, { driver: :hiredis, url: ENV.fetch('REDIS_URL') }", env: 'production'
  
  code = <<-DONE
  config.session_store :redis_session_store, {
    key:        Rails.application.credentials.app_session_key,
    serializer: :json,
    redis:      {
      expire_after: 1.year,
      ttl: 1.year,
      key_prefix: 'app:session:',
      url: ENV.fetch('REDIS_URL')
    }
  }
  DONE
  environment code, env: 'production'
end

def configure_sidekiq
  say "Configuring Sidekiq..."

  insert_into_file "config/routes.rb", "require 'sidekiq/web'\n\n", before: "Rails.application.routes.draw do"
  code = <<-DONE
  mount Sidekiq::Web => '/sidekiq'

  DONE
  insert_into_file "config/routes.rb", "#{code}\n", after: "Rails.application.routes.draw do\n"
  environment "config.active_job.queue_adapter = :sidekiq"
end

def update_git_ignore
  append_to_file '.gitignore', "ruby\nvendor\n.env\n"
end

copy_app_files
update_gems
run 'bundle install'
after_bundle do
  install_node_packages
  install_hotwire_and_redis
  add_home_page
  add_todo_routes
  update_javascript_resources
  add_scss_resources
  add_image_resources
  update_application_layout
  configure_action_cable
  configure_redis_cache
  configure_sidekiq
  update_git_ignore
end
