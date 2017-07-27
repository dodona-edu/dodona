# Dodona

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

Students can sign in with their UGent credentials after which an account is created automatically. On submission, their solutions gets stored on the server and a sandboxed background job is started to test the solution.

* Production version: http://dodona.ugent.be
* Development version: http://naos.ugent.be

Take a look at [the wiki](https://github.ugent.be/dodona/dodona/wiki) for more information about writing judges and exercises.

## Development Setup

1. Install and start `mysql` or `mariadb`.
2. Create dodona user (with password 'dodona') with create database permissions.
3. Create and seed the database with `rake db:setup`. (If something goes wrong with the database, you can use `rake db:reset` to drop, rebuild and reseed the database.)
4. Start the server with `rails s` (if the server freezes, restart it).
5. Because CAS authentication does not work in development, you have to log in manually. You can do this by writing the line `sign_in User.first`in the beginning of the `set_locale` function in `app/controllers/application_controller.rb`. When you reload the page you should be logged in. **Do not forget to remove this line, so you don't accidentally commit this change.**

## Evaluating exercises
This is optional, but needed to actually evaluate exercises.

1. Install and start `docker`.
2. Clone the [docker-images repository](https://github.ugent.be/dodona/docker-images).
3. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-anaconda3` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-anaconda3" -f "dodona-anaconda3.dockerfile" .`.
4. Start the delayed_job runner with `bin/delayed_job start` to process the submission queue.

