SHELL         := /usr/bin/env bash
.SHELLFLAGS   := -o pipefail -euc
.DEFAULT_GOAL := build
account       := 937369328181
tag           ?= $(shell git rev-parse --short=7 HEAD)

pull:
	test -d ../deploy          || git clone git@github.com:DensityCo/deploy.git ../deploy
	test -d ../terraform-nomad || git clone git@github.com:DensityCo/terraform-nomad.git ../terraform-nomad

build: pull
	../deploy/docker/build density/partkeepr 'partkeepr/'
	../deploy/docker/build density/partkeepr-oauth-proxy 'oauth-proxy'

push: pull
	../deploy/docker/push $(account) density/partkeepr $(tag)
	../deploy/docker/push $(account) density/partkeepr-oauth-proxy $(tag)

run:
	docker run -d --name $(name) $(image):0

stop:
	docker kill $(name)

clean:
	docker rm $(name)

deploy/partkeepr/factory: pull
	../deploy/terraform/deploy factory-us-east-1 factory
