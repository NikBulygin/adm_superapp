SHELL := /bin/bash

COMPOSE_FILE := docker-compose.yaml
BRANCH := $(shell git symbolic-ref --short -q HEAD 2>/dev/null || echo dev)
SHORT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo local)
ENVIRONMENT ?= $(if $(filter main,$(BRANCH)),prod,dev)
APP_MODE := $(if $(filter prod,$(ENVIRONMENT)),PROD,DEV)

ifeq ($(ENVIRONMENT),prod)
IMAGE_TAG := main-$(SHORT_SHA)
else
IMAGE_TAG := dev-$(SHORT_SHA)
endif

AUTH_IMAGE ?= ghcr.io/nikbulygin/adm_auth
FRONTEND_IMAGE ?= ghcr.io/nikbulygin/adm_frontend
BACKEND_IMAGE ?= ghcr.io/nikbulygin/adm_backend

ENV_FILE := $(shell if [ -f ".env.$(ENVIRONMENT)" ]; then echo ".env.$(ENVIRONMENT)"; elif [ -f ".env.$(ENVIRONMENT).example" ]; then echo ".env.$(ENVIRONMENT).example"; elif [ -f ".env" ]; then echo ".env"; else echo ".env.example"; fi)

export ENVIRONMENT APP_MODE IMAGE_TAG AUTH_IMAGE FRONTEND_IMAGE BACKEND_IMAGE

.PHONY: help init submodule-sync build up down ci-build ci-push print-vars

help:
	@echo "adm_superApp: краткий порядок запуска"
	@echo ""
	@echo "1) make init           - инициализировать submodule"
	@echo "2) make build          - собрать Docker-образы"
	@echo "3) make up             - запустить стек (detached)"
	@echo "4) make down           - остановить стек"
	@echo "   (по умолчанию ENVIRONMENT=dev; для prod: make ENVIRONMENT=prod <target>)"
	@echo ""
	@echo "Дополнительно:"
	@echo "   make submodule-sync - синхронизировать и обновить submodule"
	@echo "   make print-vars     - показать BRANCH/SHORT_SHA/IMAGE_TAG"
	@echo "   make ci-build       - сборка образов для CI"
	@echo "   make ci-push        - push образов в registry"

init:
	git submodule update --init --recursive

submodule-sync:
	git submodule sync --recursive
	git submodule update --init --recursive --remote

build:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) build

up:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d --build

down:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

ci-build:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) build

ci-push:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) push

print-vars:
	@echo "BRANCH=$(BRANCH)"
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "APP_MODE=$(APP_MODE)"
	@echo "ENV_FILE=$(ENV_FILE)"
	@echo "SHORT_SHA=$(SHORT_SHA)"
	@echo "IMAGE_TAG=$(IMAGE_TAG)"
	@echo "AUTH_IMAGE=$(AUTH_IMAGE)"
	@echo "FRONTEND_IMAGE=$(FRONTEND_IMAGE)"
	@echo "BACKEND_IMAGE=$(BACKEND_IMAGE)"
