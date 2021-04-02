#!/bin/bash

set -e
# set -x

if [[ "$DB_RESET" = "true" && "$RAILS_ENV" = "production" ]]; then
    echo "You are not allowed to run rails db:reset in production!"
    exit 1
fi

wait-for-it database:5432 -t 60

# bundle install
# yarn install --check-files

if [[ "$DB_RESET" = "true" ]] || ! bundle exec rails db:has_loaded_schema; then
    bundle exec rails db:drop db:create
    if [[ -f db/schema.rb ]]; then
        bundle exec rails db:schema:load
    fi
    bundle exec rails db:migrate db:seed
else
    bundle exec rails db:migrate
fi

bundle exec puma -C config/puma.rb -p 4000
