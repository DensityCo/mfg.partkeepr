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
deploy/lab:
	$(call check_var, tag, required to render this template)
	ENVIRON=lab-us-east-1 \
	SERVICE_NAME=partkeepr-staging \
	DOCKER_IMAGE="$(namespace)/$(image):$(tag)" \
  COUNT=2 \
	.circleci/send.sh
deploy-lab: deploy/lab

# https://stackoverflow.com/a/649462/4115328
define NGINX_STAGING_BUILD_TLD
server {
	listen 80;
	server_name partkeepr.density.build;
	location / {
		proxy_pass https://production-us-east-1.density.io;
		proxy_next_upstream error timeout invalid_header http_500 http_503 http_504;
		proxy_redirect off;
		proxy_set_header Host partkeepr-staging.density.io;
		proxy_set_header X-Forwarded-Proto $$http_x_forwarded_proto;
		proxy_set_header X-Real-IP $$remote_addr;
		proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
		proxy_http_version 1.1;
		proxy_set_header Connection "";
		proxy_set_header X-Request-ID $$request_trace_id;
		proxy_send_timeout 120s;
		client_max_body_size 100m;
	}
}
endef
export NGINX_STAGING_BUILD_TLD

deploy/lab/consul-keys:
	density ssh --pick-first \
		--exec "consul kv put -base64 nginx/partkeepr-staging $$(echo $$NGINX_STAGING_BUILD_TLD | base64)" \
		lab-us-east-1-cluster-worker
deploy-lab-env: deploy/lab/consul-keys


# ----------------------------------------------------------
# helpers

check_var = $(foreach 1,$1,$(__check_var))
__check_var = $(if $(value $1),,\
	$(error Missing $1 $(if $(value 2),$(strip $2))))