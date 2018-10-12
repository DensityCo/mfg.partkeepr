MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -euc
.DEFAULT_GOAL := build

namespace := 937369328181.dkr.ecr.us-east-1.amazonaws.com
tag := $(shell git rev-parse --short HEAD)
image := density/partkeepr

.PHONY: dev test test-ci build tag push deploy/lab deploy-lab deploy/lab/consul-keys deploy-lab-env deploy/staging deploy-staging deploy/staging/consul-keys deploy-staging-env deploy/production deploy-production deploy/production/consul-keys deploy-production-env

# Local development
dev:
	docker-compose up


# ----------------------------------------------------------
# build and ship

## builds partkeepr container
build:
	time docker build -t "$(image):0" .

## tags the partkeepr container; 'make tag tag=5'
tag:
	$(call check_var, tag, required to tag the image)
	docker tag "$(image):0" "$(namespace)/$(image):$(tag)"

## push the partkeepr container to the ECS registry; 'make push tag=5'
push:
	$(call check_var, tag, required to push to production)
	docker push "$(namespace)/$(image):$(tag)"


# ----------------------------------------------------------
# partkeepr configuration and deployment

## render the Nomad job and deploy to lab
deploy/staging:
	$(call check_var, tag, required to render this template)
	ENVIRON=factory-us-east-1 \
	TEMPLATE=./partkeepr.nomad.hcl \
	SERVICE_NAME=partkeepr-staging \
	DOCKER_IMAGE="$(namespace)/$(image):$(tag)" \
  COUNT=1 \
	../.circleci/send.sh
deploy-staging: deploy/staging

deploy/staging/consul-keys:
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_database_host $(PARTKEEPR_DATABASE_HOST)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_database_name $(PARTKEEPR_DATABASE_NAME)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_database_port $(PARTKEEPR_DATABASE_PORT)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_database_user $(PARTKEEPR_DATABASE_USER)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_database_pass $(PARTKEEPR_DATABASE_PASS)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_oktopart_apikey $(PARTKEEPR_OKTOPART_APIKEY)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_secret $(PARTKEEPR_SECRET)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_username $(PARTKEEPR_USERNAME)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr-staging/partkeepr_password $(PARTKEEPR_PASSWORD)" \
		factory-us-east-1-cluster-worker
deploy-staging-env: deploy/staging/consul-keys

deploy/production:
	$(call check_var, tag, required to render this template)
	ENVIRON=factory-us-east-1 \
	SERVICE_NAME=partkeepr \
	DOCKER_IMAGE="$(namespace)/$(image):$(tag)" \
  COUNT=1 \
	.circleci/send.sh
deploy-production: deploy/production

deploy/production/consul-keys:
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_database_host $(PARTKEEPR_DATABASE_HOST)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_database_name $(PARTKEEPR_DATABASE_NAME)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_database_port $(PARTKEEPR_DATABASE_PORT)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_database_user $(PARTKEEPR_DATABASE_USER)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_database_pass $(PARTKEEPR_DATABASE_PASS)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_oktopart_apikey $(PARTKEEPR_OKTOPART_APIKEY)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_secret $(PARTKEEPR_SECRET)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_username $(PARTKEEPR_USERNAME)" \
		factory-us-east-1-cluster-worker
	density ssh --pick-first \
		--exec "consul kv put partkeepr/partkeepr_password $(PARTKEEPR_PASSWORD)" \
		factory-us-east-1-cluster-worker
deploy-production-env: deploy/production/consul-keys


# ----------------------------------------------------------
# helpers

check_var = $(foreach 1,$1,$(__check_var))
__check_var = $(if $(value $1),,\
	$(error Missing $1 $(if $(value 2),$(strip $2))))
