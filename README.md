# Dodona

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

Students can sign in with their UGent credentials after which an account is created automatically. On submission, their solutions gets stored on the server and a sandboxed background job is started to test the solution.

* Production version: http://dodona.ugent.be
* Development version: http://naos.ugent.be

Take a look at [the wiki](https://github.ugent.be/dodona/dodona/wiki) for more information about writing judges and exercises.

## Development Setup

1. Install and start `mysql` or `mariadb`.
2. Create dodona user (with password 'dodona') with create database permissions.
3. Create and seed the database with `rails db:setup`. (If something goes wrong with the database, you can use `rails db:reset` to drop, rebuild and reseed the database.)
4. [Start the server](#starting-the-server). The simplest way is with `rails s`.
5. Because CAS authentication does not work in development, you have to log in manually. You can do this by writing the line `sign_in User.first`in the beginning of the `set_locale` function in `app/controllers/application_controller.rb`. When you reload the page you should be logged in. **Do not forget to remove this line, so you don't accidentally commit this change.**

## Evaluating exercises
These steps are not required to run the server, but you need docker to actually evaluate exercises.

1. Install and start `docker`.
2. Clone the [docker-images repository](https://github.ugent.be/dodona/docker-images).
3. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-anaconda3` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-anaconda3" -f "dodona-anaconda3.dockerfile" .`.

## Starting the server
The simplest way to start the server is with the `rails s` command. But this will not process the submission queue, and javascript will be compiled by webpack in the background (without output when something goes wrong).

- To process the submission queue, delayed job needs to be started with the `bin/delayed_job start` command.
- With `bin/webpack-dev-server` your javascript is reloaded live and you can see development output.

To run all these processes at the same time, the foreman gem is used. To start the rails server, delayed job and the webpack dev server, simply run `bin/server`.

This has one letdown: debugging with `byebug` is broken. You can run `bin/server norails` to only start webpack and delayed_job in foreman and then run `rails s` in a different terminal to be able to use `byebug` again.
