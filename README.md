Docker and CI Helpers on PHP
============================

This is a helper project that contains a list CI and docker tasks based on a Makefile.

The main prupose of this is to be used for automatisation of CI.

To display help tasks:

```bash
make
```

## Docker tasks

1. Install [Docker](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)
2. Install [Docker Compose](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)

List of important docker's tasks:

```bash
make docker-start  # to start a docker compose stack
```

```bash
make docker-stop  # to stop a docker compose stack
```

## Execute various CI tasks

Commands **CAN** be executed within the Docker container.
To log into the container, just run `make docker-bash`

All Logs for the ci commands will be generated inside var/logs/, you can overwrite this by passing the LOGDIR to make task:

```bash
make phpstan-ci --LOGDIR = 'my_path/'
```

### PHPStan

[Install PHPSTAN via composer][1]

Then run this commands to display results on CLI:

```bash
make phpstan 
```

If you want to dump logs that can be used for CI prupose (Jenkins), you should use this task:

```bash
make phpstan-ci # Logs will be dumped into var/ci_log/phpstan.xml
```

### PHPMD

[Install PHPMD via composer][2]

Then run this commands to display results on CLI:

```bash
make phpmd 
```

If you want to dump logs that can be used for CI prupose (Jenkins), you should use this task:

```bash
make phpmd-ci # Logs will be dumped into var/ci_log/phpmd.xml
```

### PHPCS

[Install PHPCS via composer][3]

Then run this commands to display results on CLI:

```bash
make phpcs 
```

If you want to dump logs that can be used for CI prupose (Jenkins), you should use this task:

```bash
make phpcs-ci # Logs will be dumped into var/ci_log/phpcs.xml
```

### PHPDOX

[Install PHPDOX via composer][4]

When you run this commands, it will generate the whole documentation into ./var/ci_log/phpdox:

```bash
make phpdox 
```

*Only for using this on CI server.*

### PHPCPD

[Install PHPCPD via composer][5]

Then run this commands to display results on CLI:

```bash
make phpcpd
```

If you want to dump logs that can be used for CI prupose (Jenkins), you should use this task:

```bash
make phpcpd-ci # Logs will be dumped into var/ci_log/pmd-cpd.xml
```

### PHPLOC

[Install PHPLOC via composer][6]

Then run this commands to display results on CLI:

```bash
make phploc
```

If you want to dump logs that can be used for CI prupose (Jenkins), you should use this task:

```bash
make phploc-ci # Logs will be dumped into var/ci_log/phploc.xml
```

### PDEPEND

[Install PDEPEND via composer][7]

When you run this commands, it will generate the whole graph of dependency into ./var/ci_log:

```bash
make pdepend-ci
```

*Only for using this on CI server.*

### PHPUNIT

[Install PHPUNIT via composer][8]

There are two ways to run tests, this first one with the dump of coverage on CLI and files:

```bash
make test # Logs will be dumped into var/ci_log/coverage
```

*Using unit tests with code coverage presumes that you've already a version > PHP 7.0 that includes phpdbg*

The second one, is only for running PHPUNIT tests without code coverage:

```bash
make test-no-coverage
```

## Combine CI tasks

There's another task that combine all CI taks that can be used in CI servers:

```bash
make full-build-ci
```

This executes the following steps:

1. Prepare folder for CI logs
2. Install composer
3. Execute CI tasks (phplint phploc-ci pdepend-ci phpmd-ci phpcs-ci phpcpd-ci phpstan-ci)
4. Execute unit tests with code coverage
5. Generate doc from the project

## Overload task variables

There's a various predefined variables that can be overload when executing a task as the following:

```bash
make test --LOGIR = 'var/logs'
```

### CI

* **SRCDIR** : to define a new source direcotry
* **LOGDIR** : to define a new output log directory
* **BUILDDIR** : to define a new configuration directory

### Docker

* **APPLICATION_NAME** : to define the name of application in docker-compose.yml

## License

This project is under the Apache License 2.0. See the complete license:

```
    LICENSE
```

## Contributors

See [CONTRIBUTING][9] file.

[1]: https://github.com/phpstan/phpstan#installation
[2]: https://phpmd.org/download/index.html
[3]: https://github.com/squizlabs/PHP_CodeSniffer#composer
[4]: https://github.com/theseer/phpdox#composer-installation
[5]: https://github.com/sebastianbergmann/phpcpd#composer
[6]: https://github.com/sebastianbergmann/phploc#composer
[7]: https://pdepend.org/download/index.html
[8]: https://phpunit.de/getting-started/phpunit-7.html

