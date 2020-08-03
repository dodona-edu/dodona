# Dodona 

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

On https://dodona.ugent.be, students can sign in with the credentials of the Smartschool, Office 365, or G Suite account of their school. After signing in, you can subscribe to one of the many courses. Dodona courses consist of several exercise series. Each exercise has a detailed exercise description and an extensive test suite. After submitting a solution to an exercise, a sandboxed background job is started to test the solution, and the result and feedback is displayed within seconds.

The documentation of this project can be found at https://dodona-edu.github.io.

## Development Setup

1. Install and start `mysql` or `mariadb`.
2. If using `mysql`, add `sql-mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'` to the `/etc/mysql/mysql.conf.d/mysqld.cnf` file.
3. Create dodona user (with password 'dodona') with create database permissions.
4. Create and seed the database with `rails db:setup`. (If something goes wrong with the database, you can use `rails db:reset` to drop, rebuild and reseed the database.)
5. [Start the server](#starting-the-server). The simplest way is with `rails s`. Dodona [will be available on a subdomain of localhost](#localhost-subdomain): http://dodona.localhost:3000.
6. Because CAS authentication does not work in development, you can log in by going to these pages (only works with the seed database form step 4)
   - `http://dodona.localhost:3000/nl/users/1/token/zeus`
   - `http://dodona.localhost:3000/nl/users/2/token/staff`
   - `http://dodona.localhost:3000/nl/users/3/token/student`

## Evaluating exercises locally
These steps are not required to run the server, but you need docker to actually evaluate exercises.

1. Install and start `docker`.
2. Clone the [docker-images repository](https://github.com/dodona-edu/docker-images).
3. Build a docker image. The `build.sh` scripts builds all images. But with the initial data, only `dodona-python` is needed. You can build this image with `docker build --pull --force-rm -t "dodona-python" -f "dodona-python.dockerfile" .`.

## Visualisations locally
These steps are not required to run the server, but are needed to let the visualisations work.

1. Install and start `memcached`.
2. Create the following file `tmp/caching-dev.txt`.

## Starting the server
The simplest way to start the server is with the `rails s` command. But this will not process the submission queue, and javascript will be compiled by webpack in the background (without output when something goes wrong).

- To process the submission queue, delayed job needs to be started with the `bin/delayed_job start` command.
- With `bin/webpack-dev-server` your javascript is reloaded live and you can see development output.

To run all these processes at the same time, the foreman gem is used. To start the rails server, delayed job and the webpack dev server, simply run `bin/server`.

This has one letdown: debugging with `byebug` is broken. You can run `bin/server norails` to only start webpack and delayed_job in foreman and then run `rails s` in a different terminal to be able to use `byebug` again.

## Localhost subdomain

Dodona use subdomains in order to sandbox exercise descriptions (which are arbitrary HTML pages and could be used for malicious purposes if not properly sandboxed. We serve the main application in development from http://dodona.localhost:3000 and exercise descriptions from http://sandbox.localhost:3000.

If this does not work out of the box you can add the following lines to your `/etc/hosts` file:
```
127.0.0.1             dodona.localhost
127.0.0.1             sandbox.localhost
```

## Running on Windows

Some gems (such as therubyracer) are not supported on Windows. However it is possible to run Dodona using [WSL](https://docs.microsoft.com/en-us/windows/wsl/about). Note: using [WSL2](https://docs.microsoft.com/en-us/windows/wsl/wsl2-index), these steps are probably not necessary.

* Dodona itself must be run in WSL. The Ubuntu WSL distribution is known to work.
* The database can be run in either Windows or WSL. If you run the database in Windows, you must change `host` from `localhost` to `127.0.0.1` (in `config/database.yml`). Otherwise Ruby will attempt to connect using sockets, which won't work.

### Docker

Docker runs in Windows, and requires some tweaks to communicate with WSL.

* Enable the TCP daemon in the [Docker settings](https://docs.docker.com/docker-for-windows/#general).
* Set the environment variable `DOCKER_URL` to the url of the Docker daemon. Otherwise Ruby will again attempt to connect using sockets.
* Dodona uses [bind mounts](https://docs.docker.com/storage/bind-mounts/) to share a folder with the container. As Dodona runs in WSL and Docker in Windows, this does not work out of the box.
  * By default, WSL uses paths of the form `/mnt/c/users/blabla`. However, Docker uses `/c/users/blabla`. You need to change the mount location in WSL. (See also [in this blog post](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly#ensure-volume-mounts-work) and the [reference documentation](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#set-wsl-launch-settings).)
  * Open or create the config file by running `sudo nano /etc/wsl.conf` in WSL and insert this:
    ```
    [automount]
    root = /
    options = "metadata,umask=22,fmask=11"
    ```
    This will also give Windows folders proper permissions in WSL.
  
  * There is another problem: Dodona creates a temporary folder in `/tmp` (inside WSL), which is not accessible to Docker. A solution is setting the `TMPDIR` environment variable (in WSL when running Dodona). Set `TMPDIR` to a folder on your Windows drive, like `/c/ubuntu-tmp`. As Dodona will then pass `/c/ubuntu-tmp` to Docker, it will be able to access the folder.
* This is not specific to Dodona, but when you build Docker images in Windows, you need special care to ensure files have the proper permissions (executable) and have the correct line endings.
