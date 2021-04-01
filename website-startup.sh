#!/bin/bash

set -e
# set -x

./config/docker/wait-for-mysql-server.sh

if [[ "$DB_RESET" = "true" && "$RAILS_ENV" = "production" ]]; then
    echo "You are not allowed to run rails db:reset in production!"
    exit 1
fi

bundle instal
yarn install --check-files

# if [[ "$DB_RESET" = "true" ]] || ! bundle exec rails db:has_loaded_schema; then
#     bundle exec rails db:drop
#     bundle exec rails db:create
#     bundle exec rails db:db:schema:load
#     bundle exec rails db:migrate
#     bundle exec rails db:seed
# else
#     bundle exec rails db:migrate
# fi

bundle exec puma -C config/puma.rb
