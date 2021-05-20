# Dodona 

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

On https://dodona.ugent.be, students can sign in with the credentials of the Smartschool, Office 365, or G Suite account of their school. After signing in, you can subscribe to one of the many courses. Dodona courses consist of several exercise series. Each exercise has a detailed exercise description and an extensive test suite. After submitting a solution to an exercise, a sandboxed background job is started to test the solution, and the result and feedback is displayed within seconds.

The documentation of this project can be found at https://docs.dodona.be.

## Dodona development

### Development Setup

1. Install and start `mysql` or `mariadb`.
2. If using `mysql`, change the `sql-mode` in the `mysqld` configuration block:
    ```
    sql-mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    ```
3. Create a `dodona` user with access to the `dodona` and `dodona_test-N` databases. You will need as much test databases as hou have CPU threads.
    ```sql
    CREATE USER 'dodona'@'localhost' IDENTIFIED BY 'dodona';
    GRANT ALL ON dodona.* TO 'dodona';
    GRANT ALL ON dodona_test.* TO 'dodona';
    GRANT ALL ON dodona_test-0.* TO 'dodona';
    ...
    GRANT ALL ON dodona_test-3.* TO 'dodona';
    ```
4. Create and seed the database with `rails db:setup`. (If something goes wrong with the database, you can use `rails db:reset` to drop, rebuild and reseed the database.)
5. [Start the server](#starting-the-server). The simplest way is with `rails s`. Dodona [will be available on a subdomain of localhost](#localhost-subdomain): http://dodona.localhost:3000.
6. Because CAS authentication does not work in development, you can log in by going to these pages (only works with the seed database form step 4)
   - `http://dodona.localhost:3000/nl/users/1/token/zeus`
   - `http://dodona.localhost:3000/nl/users/2/token/staff`
   - `http://dodona.localhost:3000/nl/users/3/token/student`

#### Evaluating exercises locally
These steps are not required to run the server, but you need docker to actually evaluate exercises.

1. Install and start `docker`.
2. Clone the [docker-images repository](https://github.com/dodona-edu/docker-images).
3. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-python` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-python" -f "dodona-python.dockerfile" .`.

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

Dodona use subdomains in order to sandbox exercise descriptions (which are arbitrary HTML pages and could be used for malicious purposes if not properly sandboxed. We serve the main application in development from http://dodona.localhost:3000 and exercise descriptions from http://sandbox.localhost:3000.

If this does not work out of the box you can add the following lines to your `/etc/hosts` file:
```
127.0.0.1             dodona.localhost
127.0.0.1             sandbox.localhost
```
