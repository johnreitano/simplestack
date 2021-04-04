ifndef $(ENV)
	ENV=development
endif
ENVS := test development staging production
ifeq ($(filter $(ENV),$(ENVS)),)
	$(error ENV is set to an unrecognized value '$(ENV)')
	exit 1
endif

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
_PARENT_DIR_WITH_SLASH := $(dir $(MAKEFILE_PATH))
SIMPLESTACK_PATH := $(patsubst %/,%,$(_PARENT_DIR_WITH_SLASH))
APP_NAME=$(shell basename $(PWD))
HEROKU_APP_NAME=simplestack-$(shell basename $(PWD))
DOCKER_COMPOSE=docker-compose -p simplestack-$(APP_NAME) -f docker/docker-compose.yml

DEFAULT_GOAL := help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsasge for making simplestack targets:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

setup: ## setup all containers from scratch (destroys existing containers and db)
	$(DOCKER_COMPOSE) down --remove-orphans
	$(DOCKER_COMPOSE) rm -fs
	if [[ "$(nobuild)" != "true" ]]; then touch Gemfile.lock; $(DOCKER_COMPOSE) build --pull; fi
	DB_RESET=true $(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans # DANGER: destroys db!

create-github-repo:
	$(SIMPLESTACK_PATH)/create-github-repo.sh

up: ## start up all containers
	$(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans

down: ## shut down all containers
	$(DOCKER_COMPOSE) down --remove-orphans

console: ## run rails console
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rails console"

test: ## run tests
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rails test"

migrate-db: ## migrate database
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rails db:migrate"

rubocop: ## run rubocop
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rubocop"

rubocop-a: ## run rubocop with auto-correct
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rubocop -A"

bundle-install: ## run bundle install
	$(DOCKER_COMPOSE) exec website bash -c "bundle install"

logs: ## tails the log for the main api container
	$(DOCKER_COMPOSE) logs -f website

logs-worker: ## tails the log for the worker container
	$(DOCKER_COMPOSE) logs -f worker

build: ## build all containers
	touch Gemfile.lock
	$(DOCKER_COMPOSE) build --parallel

reset-db: ## resets db (drop, create, schema load, seed)
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rails db:reset"

seed-db: ## seed database
	$(DOCKER_COMPOSE) exec website bash -c "bundle exec rails db:seed"

bash: ## get a bash shell on the main api container (optionally run a command in the shell)
	if [[ -z "$(cmd)" ]]; then \
		$(DOCKER_COMPOSE) exec website bash; \
	else \
		$(DOCKER_COMPOSE) exec website bash -c "$(cmd)"; \
	fi

attach: ## attach to website container in order to use byebug console (press ctrl-p ctrl-q to quit)
	@echo "Attaching to website container. Press CTRL-p CTRL-q to quit..."
	docker container attach simplestack-$(APP_NAME)_website_1

attach-worker: ## attach to worker container in order to use byebug console
	@echo "Attaching to worker container. Press CTRL-p CTRL-q to quit..."
	docker container attach simplestack-$(APP_NAME)_worker_1

deploy: ## deploy (only production for now)
	@echo "Deploying to $(RAILS_ENV) environment..."
	if ! heroku apps:info $(HEROKU_APP_NAME) 1>/dev/null 2>/dev/null; then \
		heroku apps:create $(HEROKU_APP_NAME); \
		heroku addons:create heroku-redis:hobby-dev --app=$(HEROKU_APP_NAME); \
		heroku addons:wait --app=$(HEROKU_APP_NAME); \
	fi
	git push heroku master
	heroku run rake db:migrate
	@echo NOTE: To destroy this app, run: heroku apps:destroy --app=$(HEROKU_APP_NAME)

# function used above
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Please set a value for environment variable $1$(if $2, ($2))))

