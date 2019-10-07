# Dodona 

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

On https://dodona.ugent.be, students can sign in with the credentials of the Smartschool, Office 365, or G Suite account of their school. After signing in, you can subscribe to one of the many courses. Dodona courses consist of several exercise series. Each exercise has a detailed exercise description and an extensive test suite. After submitting a solution to an exercise, a sandboxed background job is started to test the solution, and the result and feedback is displayed within seconds.

The documentation of this project can be found at https://dodona-edu.github.io.

## Development Setup

1. Install and start `mysql` or `mariadb`.
2. If using `mysql`, add `sql-mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'` to the `/etc/mysql/mysql.conf.d/mysqld.cnf` file.
3. Create dodona user (with password 'dodona') with create database permissions.
4. Create and seed the database with `rails db:setup`. (If something goes wrong with the database, you can use `rails db:reset` to drop, rebuild and reseed the database.)
5. [Start the server](#starting-the-server). The simplest way is with `rails s`.
6. Because CAS authentication does not work in development, you can log in by going to these pages (only works with the seed database form step 4)
   - `http://localhost:3000/nl/users/1/token/zeus`
   - `http://localhost:3000/nl/users/2/token/staff`
   - `http://localhost:3000/nl/users/3/token/student`

## Evaluating exercises locally
These steps are not required to run the server, but you need docker to actually evaluate exercises.

1. Install and start `docker`.
2. Clone the [docker-images repository](https://github.com/dodona-edu/docker-images).
3. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-anaconda3` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-anaconda3" -f "dodona-anaconda3.dockerfile" .`.

## Starting the server
The simplest way to start the server is with the `rails s` command. But this will not process the submission queue, and javascript will be compiled by webpack in the background (without output when something goes wrong).

- To process the submission queue, delayed job needs to be started with the `bin/delayed_job start` command.
- With `bin/webpack-dev-server` your javascript is reloaded live and you can see development output.

To run all these processes at the same time, the foreman gem is used. To start the rails server, delayed job and the webpack dev server, simply run `bin/server`.

This has one letdown: debugging with `byebug` is broken. You can run `bin/server norails` to only start webpack and delayed_job in foreman and then run `rails s` in a different terminal to be able to use `byebug` again.

## Tutor Docker network

Your docker network (for the python tutor) should be in `192.168.0.0/16`. If this is not the case, you should edit `Rails.config.tutor_docker_network_prefix` in `config/application.rb`. Be aware that you should run this application behind a proxy, otherwise users could spoof their IP address via the `X-Forwarder-For` header. (If they spoof their ip addres to one within the docker network, they will be able to access media files of private exercises that they would otherwise not have access to.)
