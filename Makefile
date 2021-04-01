ifndef $(ENV)
	ENV=development
endif
ENVS := test development staging production
ifeq ($(filter $(ENV),$(ENVS)),)
	$(error ENV is set to an unrecognized value '$(ENV)')
	exit 1
endif

DOCKER_COMPOSE=docker-compose -p auto-api
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
_PARENT_DIR_WITH_SLASH := $(dir $(MAKEFILE_PATH))
SIMPLE_STACK_PATH := $(patsubst %/,%,$(_PARENT_DIR_WITH_SLASH))
APP_NAME=$(firstword $(SIMPLE_STACK_ARGS))

DEFAULT_GOAL := help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsasge for making auto-api targets:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

new: ## create a new simplestack app based on rails, hotwire, postgres and heroku 
	@echo "Creating application $(lastword $(SIMPLE_STACK_ARGS)) from SimpleStack template..."
	rails new --skip-spring --skip-sprockets --database=postgresql -m $(SIMPLE_STACK_PATH)/template.rb $(SIMPLE_STACK_ARGS)
	cd $(APP_NAME) && $(SIMPLE_STACK_PATH)/create-github-repo.sh
	@echo -n "\nCongratulations, your SimpleStack app is ready!\n\nStart your server by running \"cd $(APP_NAME); rails server\" and then visit http://localhost:3000"

setup: ## setup all containers from scratch (destroys existing containers and db)
	if [[ ! -e .env ]]; then echo "Error: missing .env file!"; exit 1; fi
	$(DOCKER_COMPOSE) down --remove-orphans
	$(DOCKER_COMPOSE) rm -fs
	docker volume rm -f auto-api_mysql-data
	if [[ "$(nobuild)" != "true" ]]; then $(DOCKER_COMPOSE) build --pull --parallel; fi
	DB_RESET=true $(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans # DANGER: destroys db!

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
	docker container attach auto-api_website_1

attach-worker: ## attach to worker container in order to use byebug console
	@echo "Attaching to worker container. Press CTRL-p CTRL-q to quit..."
	docker container attach auto-api_worker_1

deploy: ## deploy to RAILS_ENV (only production for now)
	$(call check_defined, RAILS_ENV)
	@echo "Deploying to $(RAILS_ENV) environment..."	
	heroku create
	heroku_app_name=`git remote -v | grep heroku | head -1 | cut -f4 -d\/ | cut -f1 -d\.`
	heroku addons:create heroku-redis:hobby-dev --app=#{heroku_app_name}
	heroku addons:wait --app=#{heroku_app_name}
	git push heroku master
	@echo NOTE: To destroy this app, run: heroku apps:destroy --app=#{heroku_app_name}

# function used above
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Please set a value for environment variable $1$(if $2, ($2))))

