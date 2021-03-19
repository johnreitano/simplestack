require 'byebug'

def ask_questions
  if answered_yes?("\nCreate remote repo in Github?  (Y/n)")
    dir_name = File.basename(Dir.getwd)
    @github_repo_name = ask("\nGithub repo name?  (#{dir_name})")    
    @github_repo_name = dir_name if @github_repo_name.blank?

    logged_in = system 'gh auth status'
    unless logged_in
      logged_in  = system 'gh auth login'
      abort('Could not login to github - quitting') unless logged_in
    end

    @github_repo_exists = system("gh repo view #{@github_repo_name} 1>/dev/null 2>/dev/null")
    abort("Github repo #{@github_repo_name} already exists - quitting") if @github_repo_exists && !answered_yes?("\nRepo exists - overwrite with push?  (Y/n)")
  end

  if answered_yes?("\nDeploy app to Heroku?  (Y/n)")
    @heroku_deployment_requested = true
    logged_in = system 'heroku auth:whoami 1>/dev/null 2>/dev/null'
    unless logged_in
      success  = system 'heroku auth:login'
      abort('Could not login to heroku - quitting') unless success
    end
  end
end

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

  gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
  gem 'hiredis'
  gem 'redis-session-store'
  gem 'bootstrap'
  gem 'font-awesome-rails'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'
  gem 'hotwire-rails'

  gem_group :development, :test do
    gem 'rubocop', require: false
  end
end

def install_hotwire
  rails_command 'hotwire:install'
end

def add_home_page
  say "Adding home page..."

  generate 'controller pages home --no-stylesheets --no-helper'
  route "root to: 'pages#home'"
  remove_file 'app/views/pages/home.html.erb'
  create_file 'app/views/pages/home.html.erb', <<-'DONE'
  <h1>Welcome to <%= Rails.application.class.to_s.split('::').first %></h1>

  <p>This application was built using <%= link_to 'Simple Stack', 'https://github.com/johnreitano/simplestack' %>.</p>
  <p>Here is <%= link_to "an example of Simple Stack in action", todo_items_path %>.
  DONE
end

def add_todo_example
  say "Adding Todo example..."

  say "cp -R #{__dir__}/todo_example_src/* ./"
  run "cp -R #{__dir__}/todo_example_src/* ./"
  route "resources :todo_items"
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

  create_file 'app/javascript/controllers/index.js', <<-'DONE'
  const controllers = require.context('.', true, /_controller\.js$/)
  DONE
end

def add_scss_resources
  say "Adding javascript resources..."

  create_file 'app/javascript/scss/global.scss', <<-'DONE'
    @import '~bootstrap/scss/bootstrap';
  DONE
end

def add_image_resources
  say "Adding image resources..."

  create_file 'app/javascript/images/index.js', <<-'DONE'
  const images = require.context('../images', true)
  const imagePath = (name) => images(name, true)
  DONE
end

def update_application_layout
  say "Updating application layout..."

  gsub_file 'app/views/layouts/application.html.erb', /_link_tag/, '_pack_tag' 
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

def init_db
  say "Initializing db..."

  rails_command 'db:create db:migrate db:seed'
end

def install_node_packages
  say "Installing node packages..."

  run 'yarn add bootstrap jquery popper.js @fortawesome/fontawesome-free' # TODO: move font-awesome to example step
end

# def configure_action_cable
#   say "Configuring action cable..."

#   # TODO: check if this is still necessary
#   gsub_file 'config/cable.yml', /development:\n *adapter: async/, "development:\n  adapter: <%= ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' } %>"
# end

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

def configure_rubocop
  say "Configuring Rubocop..."

  copy_file "#{__dir__}/rubocop.yml", '.rubocop.yml'
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

def github_repo_requested?
  @github_repo_name.present?
end

def heroku_deployment_requested?
  @heroku_deployment_requested.present?
end

def answered_yes?(prompt)
  response = ask(prompt)
  response.blank? || response.match?(/^y/i)
end

def create_local_git_changes
  return if @local_git_changes_committed
  append_to_file '.gitignore', "ruby\n" if File.readlines('.gitignore').grep(/^ruby$/).empty?
  append_to_file '.gitignore', "vendor\n" if File.readlines('.gitignore').grep(/^vendor$/).empty?
  git add: "."
  git commit: "-a -m 'Initial commit'"
  @local_git_changes_committed = true
end

def create_github_repo
  say "Creating Github repo..."

  create_local_git_changes
  success = system "gh repo create #{@github_repo_name} --confirm --public"
  abort('Could not create remote repo in Github - quitting') unless success
  git push: 'origin master'
  end

def deploy_to_heroku
  say "Deploying to Heroku..."

  create_local_git_changes
  success = system "heroku create"
  abort("Could not create Heroku application - quitting") unless success
  heroku_app_name=`git remote -v | grep heroku | head -1 | cut -f4 -d\/ | cut -f1 -d\.`
  success = system "heroku addons:create heroku-redis:hobby-dev --app=#{heroku_app_name}"
  abort("Could not create Redis add-on in Heroku - quitting") unless success
  success = system "heroku addons:wait --app=#{heroku_app_name}" if success
  abort("Could not get status of Redis add-on in Heroku - quitting") unless success
  git push: 'heroku master'
  say "NOTE: To destroy this app, run: heroku apps:destroy --app=#{heroku_app_name}"
end

ask_questions
update_gems
run 'bundle install'
after_bundle do
  install_hotwire
  install_node_packages
  add_home_page
  add_todo_example
  update_javascript_resources
  add_scss_resources
  add_image_resources
  update_application_layout
  # configure_action_cable
  configure_redis_cache
  configure_rubocop  
  configure_sidekiq
  init_db
  create_github_repo if github_repo_requested?
  deploy_to_heroku if heroku_deployment_requested?
end
