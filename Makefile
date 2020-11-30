ifndef $(ENV)
	ENV=development
endif
ENVS := test development staging production
ifeq ($(filter $(ENV),$(ENVS)),)
	$(error ENV is set to an unrecognized value '$(ENV)')
	exit 1
endif

DOCKER_COMPOSE=docker-compose -p auto-api

DEFAULT_GOAL := help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsasge for making auto-api targets:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

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
	echo "Attaching to website container. Press CTRL-p CTRL-q to quit..."
	docker container attach auto-api_website_1

attach-worker: ## attach to worker container in order to use byebug console
	echo "Attaching to worker container. Press CTRL-p CTRL-q to quit..."
	docker container attach auto-api_worker_1

deploy: ## deploy to ENV (development, personal, staging, or production)
	$(call check_defined, RAILS_ENV)
	echo "do a buncha stuff here to deploy to $(RAILS_ENV) environment..."	

db-tunnel-staging: ## run the console against the staging database using an ssh tunnel
	$(call check_defined, DB_USERNAME)
	$(call check_defined, DB_PASSWORD)
	pkill -6 -f "ssh -i" || :
	ssh -i ~/.ssh/id_rsa -N -L 3308:autoapidbstack-autoapidbclustere843232a-rf800phvleg4.cluster-cx3f68ulrzy7.us-west-2.rds.amazonaws.com:3306 ec2-user@ec2-54-191-235-227.us-west-2.compute.amazonaws.com &
	# mysql -h 127.0.0.1 -P 3308 -u saltyroot -D saltyauto_staging -p
	$(DOCKER_COMPOSE) run --no-deps -e DB_USERNAME -e DB_PASSWORD -e DB_HOST=docker.for.mac.localhost -e DB_PORT=3308 -e DB_NAME=saltyauto_staging -e RAILS_ENV=staging website bash

db-tunnel-production: ## run the console against the production database using an ssh tunnel
	$(call check_defined, DB_USERNAME)
	$(call check_defined, DB_PASSWORD)
	pkill -6 -f "ssh -i" || :
	ssh -i ~/.ssh/id_rsa -N -L 3308:autoapidbstack-autoapidbclustere843232a-bsgyhn6zwb53.cluster-cxq64vquwt8f.us-west-2.rds.amazonaws.com:3306 ec2-user@ec2-18-236-91-178.us-west-2.compute.amazonaws.com &
	$(DOCKER_COMPOSE) run --no-deps -e DB_USERNAME -e DB_PASSWORD -e DB_HOST=docker.for.mac.localhost -e DB_PORT=3308 -e DB_NAME=saltyauto_production -e RAILS_ENV=production website bash

# function used above
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Please set a value for environment variable $1$(if $2, ($2))))

