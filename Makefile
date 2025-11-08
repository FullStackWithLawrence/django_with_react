SHELL := /bin/bash
S3_BUCKET := SET-ME-PLEASE
CLOUDFRONT_DISTRIBUTION_ID := SET-ME-PLEASE

ifeq ($(OS),Windows_NT)
    PYTHON := python.exe
    ACTIVATE_VENV := venv\Scripts\activate
else
    PYTHON := python3.13
    ACTIVATE_VENV := source venv/bin/activate
endif
PIP := $(PYTHON) -m pip


.PHONY: analyze pre-commit init lint clean help

# Default target executed when no arguments are given to make.
all: help

analyze:
	cloc . --exclude-ext=svg,json,zip --vcs=git


# -------------------------------------------------------------------------
# Install and run pre-commit hooks
# -------------------------------------------------------------------------
pre-commit:
	pre-commit install
	pre-commit autoupdate
	pre-commit run --all-files

# ---------------------------------------------------------
# create python virtual environments for dev as well
# as for the Lambda layer.
# ---------------------------------------------------------
init:
	make api-clean
	npm install && \
	$(PYTHON) -m venv venv && \
	$(ACTIVATE_VENV) && \
	$(PIP) install --upgrade pip && \
	$(PIP) install -r requirements.txt && \
	deactivate && \
	cd ./api/terraform/python/layer_genai/ && \
	$(PYTHON) -m venv venv && \
	$(ACTIVATE_VENV) && \
	$(PIP) install --upgrade pip && \
	$(PIP) install -r requirements.txt && \
	$(PYTHON) -m spacy download en_core_web_sm
	deactivate && \
	pre-commit install

lint:
	terraform fmt -recursive
	pre-commit run --all-files
	black ./api/terraform/python/
	flake8 api/terraform/python/
	pylint api/terraform/python/openai_api/**/*.py

clean:
	rm -rf venv
	rm -rf ./api/terraform/python/layer_genai/venv
	rm -rf ./api/terraform/build/
	mkdir -p ./api/terraform/build/
	find ./api/terraform/python/ -name __pycache__ -type d -exec rm -rf {} +


######################
# HELP
######################

help:
	@echo '===================================================================='
	@echo 'clean               - remove all build, test, coverage and Python artifacts'
	@echo 'lint                - run all code linters and formatters'
	@echo 'init                - create environments for Python, NPM and pre-commit and install dependencies'
	@echo 'build               - create and configure AWS infrastructure resources and build the React app'
	@echo 'run                 - run the web app in development mode'
	@echo 'analyze             - generate code analysis report'
	@echo 'coverage            - generate code coverage analysis report'
	@echo 'release             - force a new release'
	@echo '-- AWS API Gateway + Lambda --'
	@echo 'api-init            - create a Python virtual environment and install dependencies'
	@echo 'api-test            - run Python unit tests'
	@echo 'api-lint            - run Python linting'
	@echo 'api-clean           - destroy the Python virtual environment'
	@echo '-- React App --'
	@echo 'client-clean        - destroy npm environment'
	@echo 'client-init         - run npm install'
	@echo 'client-lint         - run npm lint'
	@echo 'client-update       - update npm packages'
	@echo 'client-run          - run the React app in development mode'
	@echo 'client-build        - build the React app for production'
	@echo 'client-release      - deploy the React app to AWS S3 and invalidate the Cloudfront CDN'
