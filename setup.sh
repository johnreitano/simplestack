#!/usr/bin/env bash

# setting up routes

# brew list redis || brew install redis
# brew services restart redis

APP_NAME=$1
rails new -m template.rb $APP_NAME --webpack --skip-sprockets --skip-bundle
# rails new foo --skip-spring --skip-sprockets -m template.rb $APP_NAME

cd $APP_NAME

bundle add nested_scaffold redis bootstrap font-awesome-rails
bundle exec rails g scaffold TodoList title
bundle exec rails g nested_scaffold TodoList/TodoItem description:text completed:boolean completed_at:datetime todo_list:references
rm -f app/assets/stylesheets/scaffolds.scss

sed -i'' "s/# For details.*/root 'todo_lists#index'/" config/routes.rb

sed -i'' "s/_link_tag/_pack_tag/g" app/views/layouts/application.html.erb
yarn add bootstrap jquery popper.js # may be able to remove some of these

sed -i'' 's/adapter: async/adapter: redis\n  url: <%= ENV.fetch\("REDIS_URL"\) { "redis:\/\/localhost:6379\/1" } %>/' config/cable.yml
bundle exec rails db:migrate

# TODO: add templates show & index
sed -i'' -z "s/def show *\n *end/def show\n    @todo_item = TodoItem.new\n  end/" app/controllers/todo_lists_controller.rb

bundle add stimulus_reflex --version 3.3.0
bundle exec rails stimulus_reflex:install
bundle exec rails g stimulus_reflex TodoItem

mkdir -p app/javascript/images
cat > app/javascript/images/index.js << DONE
const images = require.context('../images', true)
const imagePath = (name) => images(name, true)

DONE

mkdir -p app/javascript/scss
cat > app/javascript/scss/global.scss <<"DONE"
@import '~bootstrap/scss/bootstrap';

DONE

mkdir -p app/javascript/js
cat > app/javascript/js/index.js <<"DONE"
window.App || (window.App = {});
// require("./channels")

DONE

cat > app/javascript/packs/application.js <<"DONE"
require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()

import 'bootstrap'
import 'font-awesome'
require("../images")
import '../scss/global.scss'
require("../js")

DONE

cat > app/views/layouts/application.html.erb <<"DONE"
<!DOCTYPE html>
<html>
  <head>
    <title>StimulusReflexDemoCode</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  </head>

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
</html>

DONE

cat > app/views/todo_lists/index.html.erb <<"DONE"
<div class="card-header d-flex justify-content-between">
  <span>Todo Lists</span>
  <%= link_to 'New Todo List', new_todo_list_path, class: 'btn btn-primary btn-sm' %>
</div>

<ul class="list-group">
  <% @todo_lists.each do |todo_list| %>
    <li class="list-group-item">
      <%= link_to todo_list.title, todo_list %>
    </li>
  <% end %>
</ul>

DONE

cat > app/views/todo_lists/show.html.erb <<"DONE"
<p id="notice"><%= notice %></p>

<p>
  <strong>Title:</strong>
  <%= @todo_list.title %>
</p>

<ul>
  <% @todo_list.todo_items.each do |todo_item| %>
    <li><%= todo_item.description %></li>
  <% end %>
</ul>

<%= link_to 'Edit', edit_todo_list_path(@todo_list) %> |
<%= link_to 'Back', todo_lists_path %>

DONE


# cat > app/assets/stylesheets/home.scss <<"DONE"
# .big {
#     font-size: 30px;
# }

# .colorful {
#     color: orange;
# }

# DONE

rails server -p 4000
