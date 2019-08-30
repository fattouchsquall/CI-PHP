SHELL = /bin/sh

# Colors
COLOR_END     = \033[0m
COLOR_INFO    = \033[36m
COLOR_COMMENT = \033[33m
COLOR_GROUP   = \033[1m

# CI variables
PDEPEND = vendor/bin/pdepend
PHPCPD = vendor/bin/phpcpd
PHPCS = vendor/bin/phpcs
PHPDOX = vendor/bin/phpdox
PHPLOC = vendor/bin/phploc
PHPMD = vendor/bin/phpmd
PHPSTAN = vendor/bin/phpstan
PHPUNIT = vendor/bin/phpunit
PHPDBG = phpdbg
BUILDDIR = $(CURDIR)/build
LOGDIR = $(CURDIR)/var/ci_log
SRCDIR = $(CURDIR)/src

# Docker variables
APPLICATION_NAME = my-application
LIGNES = 'all'
DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_EXEC = $(DOCKER_COMPOSE) exec $(APPLICATION_NAME)

# Symfony variables
CONSOLE = bin/console

.PHONY: 
	docker-start docker-stop docker-log docker-bash docker-inspect docker-install docker-update docker-cc docker-exec
	install@prod install update cc
	quick-build-ci full-build-ci

.DEFAULT_GOAL := help

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\n${COLOR_COMMENT}Usage:${COLOR_END}\n  make ${COLOR_INFO}<target>${COLOR_COMMENT}\n\nTargets:\n${COLOR_END}"} /^[a-zA-Z_-]+:.*?##/ { printf "  ${COLOR_INFO}%-20s${COLOR_END} %s\n", $$1, $$2 } /^##@/ { printf "\n${COLOR_GROUP}%s${COLOR_END}\n", substr($$0, 5) }' $(MAKEFILE_LIST)

###########
##@ Docker
##########
	
docker-start: ## Run (and build) docker instance
	@$(DOCKER_COMPOSE) up -d --force-recreate --build --remove-orphans

docker-stop: ## Stop docker instance
	@$(DOCKER_COMPOSE) down --remove-orphans
	
docker-log: ## Output logs of docker (to update the number of lines, you can specify the number with the argument LIGNES: make docker-log LIGNES=5)
	@$(DOCKER_COMPOSE) logs -t --tail=$(LIGNES) $(APPLICATION_NAME)

docker-bash: ## Login to docker instance
	@$(DOCKER_COMPOSE_EXEC) bash
	
docker-inspect: ## Inspect the applicatif docker container
	@docker inspect $(APPLICATION_NAME)
	
docker-install: ## Run composer install on docker
	@$(DOCKER_COMPOSE_EXEC) $(MAKE) install
	
docker-update: ## Run composer update on docker
	@$(DOCKER_COMPOSE_EXEC) $(MAKE) update
	
docker-cc: ## Run clear cache on docker
	@$(DOCKER_COMPOSE_EXEC) $(MAKE) cc
	
docker-exec: ## Execute any other make task on docker (make docker-exec TASK=test to use it)
	@$(DOCKER_COMPOSE_EXEC) $(MAKE) $(TASK)

############
##@ Install
############
	
install: export APP_ENV = dev
install: ## Run composer install
	@php -r "copy('http://getcomposer.org/composer.phar', 'composer.phar');"
	@php composer.phar install --verbose --no-interaction

update: ## Run composer update
	@php -r "copy('http://getcomposer.org/composer.phar', 'composer.phar');"
	@php composer.phar update --with-dependencies --no-interaction
	
cc: ## Clear cache
	@$(CONSOLE) c:c --no-debug
	
install@prod: export APP_ENV = prod
install@prod: ## Composer install on prod
	@php -r "copy('http://getcomposer.org/composer.phar', 'composer.phar');"
	# Composer
	@php composer.phar install --verbose --no-progress --no-interaction --prefer-dist --optimize-autoloader --no-dev
	# Symfony cache
	@bin/console cache:warmup --no-debug
	
#######
##@ CI
######
	
prepare: ## Prepare folder for CI logs
	rm -rf $(LOGDIR)
	mkdir -p $(LOGDIR)
	
phplint: ## Performs syntax check of sourcecode files
	@find ${SRCDIR}/ -name "*.php" -print0 | xargs -0 -n1 -P8 php -l

phpcs: ## Find coding standard violations using PHP_CodeSniffer and print human readable output. Intended for usage on the command line before committing.
	-@$(PHPCS) --standard=${BUILDDIR}/phpcs.xml --extensions=php ${SRCDIR}
	
phpcs-ci: ## Find coding standard violations using PHP_CodeSniffer and log result in XML format. Intended for usage within a continuous integration environment
	-@$(PHPCS) --report=checkstyle --report-file=${LOGDIR}/checkstyle.xml --standard=${BUILDDIR}/phpcs.xml --extensions=php ${SRCDIR}

phpmd: ## Perform project mess detection using PHPMD and print human readable output. Intended for usage on the command line before committing
	-@$(PHPMD) ${SRCDIR} text ${BUILDDIR}/phpmd.xml
	
phpmd-ci: ## Perform project mess detection using PHPMD and log result in XML format. Intended for usage within a continuous integration environment
	-@$(PHPMD) ${SRCDIR} xml ${BUILDDIR}/phpmd.xml --reportfile ${LOGDIR}/pmd.xml
	-@sed -i 's#/var/www/applicatif#.#' ${LOGDIR}/pmd.xml

phpcpd: ## Find duplicate code using PHPCPD and print human readable output. Intended for usage on the command line before committing.
	-@$(PHPCPD) ${SRCDIR}
	
phpcpd-ci: ## Find duplicate code using PHPCPD and log result in XML format. Intended for usage within a continuous integration environment
	-@$(PHPCPD) --log-pmd=${LOGDIR}/pmd-cpd.xml ${SRCDIR}

phploc: ## Measure project size using PHPLOC and print human readable output. Intended for usage on the command line
	-@$(PHPLOC) --count-tests ${SRCDIR}
	
phploc-ci: ## Performs syntax check of sourcecode files. Intended for usage within a continuous integration environment
	-@$(PHPLOC) --count-tests --log-csv=${LOGDIR}/phploc.csv --log-xml=${LOGDIR}/phploc.xml ${SRCDIR}
	
pdepend-ci: ## Calculate software metrics using PHP_Depend and log result in XML format. Intended for usage within a continuous integration environment
	-@$(PDEPEND) --jdepend-xml=${LOGDIR}/jdepend.xml --jdepend-chart=${LOGDIR}/dependencies.svg --overview-pyramid=${LOGDIR}/overview-pyramid.svg ${SRCDIR}
	
phpstan: ## Static analysis of code and log result in XML format. Intended for usage on the command line before committing
	-@$(PHPSTAN) analyse ${SRCDIR} --level=2
	
phpstan-ci: ## Static analysis of code and log result in XML format. Intended for usage within a continuous integration environment
	-@$(PHPSTAN) analyse ${SRCDIR} --level=2 --no-interaction --no-progress --error-format=checkstyle > ${LOGDIR}/phpstan.xml
	
phpdox: ## Generate project documentation using phpDox
	-@$(PHPDOX) --file ${BUILDDIR}/phpdox.xml

test: ## Run unit tests with PHPUnit
	@$(PHPDBG) -d memory_limit=2048M -qrr $(PHPUNIT) --configuration=./phpunit.xml.dist
	
test-no-coverage: ## Run unit tests with PHPUnit (without generating code coverage reports)
	@php -d memory_limit=2048M  $(PHPUNIT) --configuration=./phpunit.xml.dist --no-coverage
	
static-analysis-ci: ## Perform static analysis
	$(MAKE) phplint phploc-ci pdepend-ci phpmd-ci phpcs-ci phpcpd-ci phpstan-ci
	
quick-build-ci: ## Perform a lint check and runs the tests (without generating code coverage reports)
	$(MAKE) prepare install static-analysis-ci test-no-coverage
	
full-build-ci: ## Perform static analysis, runs the tests, and generates project documentation
	$(MAKE) prepare install static-analysis-ci test phpdox