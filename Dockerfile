ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_REPO
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_REPO}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}
