#!/bin/bash

set -e
# set -x

if [[ "$DB_RESET" = "true" && "$RAILS_ENV" = "production" ]]; then
    echo "You are not allowed to run rails db:reset in production!"
    exit 1
fi

bundle install
yarn install --check-files

if [[ "$DB_RESET" = "true" ]] || ! bundle exec rails db:has_loaded_schema; then
    bundle exec rails db:drop db:create db:db:schema:load rails db:migrate db:seed
else
    bundle exec rails db:migrate
fi

bundle exec puma -C config/puma.rb
