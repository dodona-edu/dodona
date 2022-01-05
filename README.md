# Dodona

![GitHub release (latest by date)](https://img.shields.io/github/v/release/dodona-edu/dodona)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dodona-edu/dodona/Test)
![Codecov](https://img.shields.io/codecov/c/github/dodona-edu/dodona)
[![Support chat](https://img.shields.io/static/v1?label=support%20chat&message=on%20matrix&color=informational)](https://matrix.to/#/#dodona-support:vanpetegem.me?via=vanpetegem.me)
[![General chat](https://img.shields.io/static/v1?label=general%20chat&message=on%20matrix&color=informational)](https://matrix.to/#/#dodona-general:vanpetegem.me?via=vanpetegem.me&via=matrix.org&via=beardhatcode.be)

> Dodona is an online exercise platform for **learning to code**. It wants to teach students how to program in the most meaningful and effective way possible. Dodona acts as an **online co-teacher**, designed to give every student access to high quality education. The focus is on automatic corrections and giving **meaningful feedback** on the submitted solutions from students.

This repository contains the source code of the web application. If you simply want to use Dodona, please go to [https://dodona.ugent.be](https://dodona.ugent.be).

The documentation for end users can be found at [https://docs.dodona.be](https://docs.dodona.be).

## Supporting Dodona

Dodona is free to use for schools and we would like to keep it that way! Keeping this platform up and running takes a lot of time, just as supporting hundreds of schools and thousands of students. If you would like to fund Dodona, you can find more information on [https://dodona.ugent.be/en/support-us/](https://dodona.ugent.be/en/support-us/) or get in touch by emailing us at dodona@ugent.be.

## Contacting us

There are several ways to contact us:
- To report a bug, please use [GitHub Issues](https://github.com/dodona-edu/dodona/issues).
- If you have a question to which the answer might be of use to others, please use [GitHub Discussions](https://github.com/dodona-edu/dodona/discussions).
- For more specific questions, use [our contact form](https://dodona.ugent.be/nl/contact/), send an email to [dodona@ugent.be](mailto:dodona@ugent.be) or come chat with us in our [general chat](https://matrix.to/#/#dodona-general:vanpetegem.me?via=vanpetegem.me&via=matrix.org&via=beardhatcode.be) or our [support chat](https://matrix.to/#/#dodona-support:vanpetegem.me?via=vanpetegem.me).

## Local development

If you want to help with development, issues tagged with the [student label](https://github.com/dodona-edu/dodona/issues?q=is%3Aissue+is%3Aopen+label%3Astudent) are a good starting point.

### Development Setup

1. Install and start `mysql` or `mariadb`.
2. If using `mysql`, change the `sql-mode` in the `mysqld` configuration block:
    ```
    sql-mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    ```
3. Create a `dodona` user with access to the `dodona` and `dodona_test-N` databases. You will need as much test databases as hou have CPU threads.
    ```sql
    CREATE DATABASE dodona;
    CREATE DATABASE dodona_test;
    CREATE DATABASE `dodona_test-0`;
    ...
    CREATE DATABASE `dodona_test-N`;
    CREATE USER 'dodona'@'localhost' IDENTIFIED BY 'dodona';
    GRANT ALL ON dodona.* TO 'dodona'@'localhost';
    GRANT ALL ON dodona_test.* TO 'dodona'@'localhost';
    GRANT ALL ON `dodona_test-0`.* TO 'dodona'@'localhost';
    ...
    GRANT ALL ON `dodona_test-N`.* TO 'dodona'@'localhost';
    ```
4. Install the correct `ruby` version using [RVM](https://rvm.io/) and install `rails`
5. Install the correct `node` version using `nvm` and [yarn](https://yarnpkg.com/)
6. Run `bundle install` and `yarn install`
7. Create and seed the database with `rails db:setup`. (If something goes wrong with the database, you can use `rails db:reset` to drop, rebuild and reseed the database.)
If the error "Could not initialize python judge" arises, use `SKIP_PYTHON_JUDGE=true rails db:setup`
8. [Start the server](#starting-the-server). The simplest way is with `rails s`. Dodona [will be available on a subdomain of localhost](#localhost-subdomain): http://dodona.localhost:3000.
9. Because CAS authentication does not work in development, you can log in by going to these pages (only works with the seed database from step 4)
   - `http://dodona.localhost:3000/nl/users/1/token/zeus`
   - `http://dodona.localhost:3000/nl/users/2/token/staff`
   - `http://dodona.localhost:3000/nl/users/3/token/student`

#### Evaluating exercises locally
These steps are not required to run the server, but you need docker to actually evaluate exercises.

1. Install and start `docker`.
2. run `docker pull dodona/dodona-python`

If you want to build the docker images yourself:
1. Clone the [docker-images repository](https://github.com/dodona-edu/docker-images).
2. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-python` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-python" -f "dodona-python.dockerfile" .`.

#### Loading visualisations locally
These steps are not required to run the server, but are needed to let the visualisations load.

1. Install and start `memcached`.
2. Create the following file `tmp/caching-dev.txt`.

#### Windows

Some gems and dependencies (such as memcached) do not work on Windows.
You should use [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/about) instead, and run everything inside WSL.
This means you use WSL for the database, memcached, git, Docker, etc.

### Starting a local server
The simplest way to start the server is with the `rails s` command. But this will not process the submission queue, and javascript will be compiled by webpack in the background (without output when something goes wrong).

- To process the submission queue, delayed job needs to be started with the `bin/delayed_job start` command.
- With `bin/webpack-dev-server` your javascript is reloaded live and you can see development output.

To start the rails server, delayed job and the webpack dev server at the same time, simply run `bin/server`.

This has one letdown: debugging with `byebug` is broken.

#### Localhost subdomain

Dodona uses subdomains in order to sandbox exercise descriptions (which are arbitrary HTML pages and could be used for malicious purposes if not properly sandboxed). We serve the main application in development from http://dodona.localhost:3000 and exercise descriptions from http://sandbox.localhost:3000.

If this does not work out of the box you can add the following lines to your `/etc/hosts` file:
```
127.0.0.1             dodona.localhost
127.0.0.1             sandbox.localhost
```

### Running linters and tests

To lint the code, run `rubocop` for Ruby and `yarn lint` for JavaScript.

We have tests in JavaScript, Ruby, and system tests:

* For JavaScript, run `yarn test`
* For the system tests, run `bundle exec rails test:system`
* For the ruby tests, run `bundle exec rails test`

**Tips**
* Use the `PARALLEL_WORKERS` ENV var to specify the number of threads to use.
* Use `TestProf` to profile the ruby tests
* Use `bundle exec rails test filename` to run a single test file, use `bundle exec rails test filename:linenumber` to run a specific test
