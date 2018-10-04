#!/bin/bash
IMAGE_NAME="nginx-alpine-openssl"
DOCKER_IMAGE_TAG="1.15.5"
docker build  --build-arg NGINX_VERSION=${DOCKER_IMAGE_TAG} --tag ${IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
