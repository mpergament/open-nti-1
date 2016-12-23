

# Determine the current git Branch and use that for docker
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
ifeq ($(BRANCH),master)
  IMAGE_TAG = latest
else
  IMAGE_TAG = $(BRANCH)
endif

TEST_TAG=unittest

PWD = $(shell pwd)
VAR_FILE ?= open-nti.params
DOCKER_FILE = docker-compose.yml
DOCKER_FILE_P = docker-compose/opennti_persistent.yml
TIME ?= 1m
TAG ?= all

#Load params file with all variables
include $(VAR_FILE)

# Define run options for Docker-compose
RUN_OPTIONS = IMAGE_TAG=$(IMAGE_TAG)

build: build-main build-jti build-syslog

build-main:
	@echo "======================================================================"
	@echo "Build Docker image - $(MAIN_IMAGE_NAME):$(IMAGE_TAG)"
	@echo "======================================================================"
	docker build -t $(MAIN_IMAGE_NAME):$(IMAGE_TAG) .

build-jti:
	@echo "======================================================================"
	@echo "Build Docker image - $(INPUT_JTI_IMAGE_NAME):$(IMAGE_TAG)"
	@echo "======================================================================"
	docker build -f $(INPUT_JTI_DIR)/Dockerfile -t $(INPUT_JTI_IMAGE_NAME):$(IMAGE_TAG) $(INPUT_JTI_DIR)

build-syslog:
	@echo "======================================================================"
	@echo "Build Docker image - $(INPUT_SYSLOG_IMAGE_NAME):$(IMAGE_TAG)"
	@echo "======================================================================"
	docker build -f $(INPUT_SYSLOG_DIR)/Dockerfile -t $(INPUT_SYSLOG_IMAGE_NAME):$(IMAGE_TAG) $(INPUT_SYSLOG_DIR)

test: test-build test-run

test-build:
	docker build -t $(MAIN_IMAGE_NAME):$(TEST_TAG) .
	docker build -f $(INPUT_JTI_DIR)/Dockerfile -t $(INPUT_JTI_IMAGE_NAME):$(TEST_TAG) $(INPUT_JTI_DIR)
	docker build -f $(INPUT_SYSLOG_DIR)/Dockerfile -t $(INPUT_SYSLOG_IMAGE_NAME):$(TEST_TAG) $(INPUT_SYSLOG_DIR)

test-run:
	python -m pytest -v

cli:
	docker exec -i -t $(MAIN_CONTAINER_NAME) /bin/bash

start:
	echo "Use docker compose file : $(DOCKER_FILE)"
	$(RUN_OPTIONS) docker-compose -f $(DOCKER_FILE) up -d

start-persistent:
	echo "Use docker compose file : $(DOCKER_FILE_P)"
	$(RUN_OPTIONS) docker-compose -f $(DOCKER_FILE_P) up -d

stop:
	echo "Use docker compose file : $(DOCKER_FILE)"
	$(RUN_OPTIONS) docker-compose -f $(DOCKER_FILE) down

stop-persistent:
	echo "Use docker compose file : $(DOCKER_FILE_P)"
	$(RUN_OPTIONS) docker-compose -f $(DOCKER_FILE_P) down

update:
	@echo "OpenNTI - Update the files from Github"
	git pull
	@echo "OpenNTI - Update the containers from Docker Hub"
	docker pull $(IMAGE_NAME):latest
	docker pull $(INPUT_JTI_IMAGE_NAME):latest
	docker pull $(INPUT_SYSLOG_IMAGE_NAME):latest

cron-show:
	# if [ $(TAG) == "all" ]; then
	#   docker exec -it $(CONTAINER_NAME) /usr/bin/python /opt/open-nti/startcron.py -a show  -c "$(TAG)"
	# else
	docker exec -it $(MAIN_CONTAINER_NAME) /usr/bin/python /opt/open-nti/startcron.py -a show  -c "/usr/bin/python /opt/open-nti/open-nti.py -s $(TAG)"

cron-add:
	docker exec -it $(MAIN_CONTAINER_NAME) /usr/bin/python /opt/open-nti/startcron.py -a add -t "$(TIME)" -c "/usr/bin/python /opt/open-nti/open-nti.py -s --tag $(TAG)"

cron-delete:
	docker exec -it $(MAIN_CONTAINER_NAME) /usr/bin/python /opt/open-nti/startcron.py -a delete  -c "/usr/bin/python /opt/open-nti/open-nti.py -s --tag $(TAG)"

cron-debug:
	docker exec -i -t $(MAIN_CONTAINER_NAME) /usr/bin/python /opt/open-nti/open-nti.py -s -c
