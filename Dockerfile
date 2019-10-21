# Set the base image.
FROM ruby:2.6.5-stretch

################################################################################
################################### PACKAGES ###################################
################################################################################

# Refresh the packages list.
RUN apt-get update

# Install MySQL server.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# Install dockerize.
RUN wget https://github.com/jwilder/dockerize/releases/download/v0.6.0/dockerize-alpine-linux-amd64-v0.6.0.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-v0.6.0.tar.gz \
    && rm dockerize-alpine-linux-amd64-v0.6.0.tar.gz

# Install NodeJS.
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt install -y nodejs

################################################################################
#################################### FILES #####################################
################################################################################

# Copy the application files and enter that directory.
COPY . /dodona
WORKDIR dodona

# Patch the seeds to clone over https instead of ssh.
RUN sed -i 's+git@github.com:dodona-edu/+https://github.com/dodona-edu/+g' db/seeds.rb
# Patch the seeds to use the java judge since that's open source.
RUN sed -i 's/judge-pythia.git/judge-java12.git/' db/seeds.rb

################################################################################
################################## DEPENDENCIES ################################
################################################################################

# Install Yarn and node packages.
RUN npm install -g yarn
RUN yarn install
# Update the bundler version.
RUN gem install bundler:2.0.2
# Install ruby dependencies for development.
RUN bundler install --without production staging test

################################################################################
################################ START THE SERVER ##############################
################################################################################

# Expose the webserver to the host.
EXPOSE 3000

# Start the database server
CMD /etc/init.d/mysql start \
    # Wait for the database server to be ready, then start the application.
    && dockerize -wait tcp://127.0.0.1:3306 -timeout 1m \
    # Dodona-specific database settings.
    && mysql -uroot -e "SET GLOBAL innodb_default_row_format=dynamic;" \
    && mysql -uroot -e "SET GLOBAL innodb_file_format=Barracuda;" \
    && mysql -uroot -e "SET GLOBAL innodb_file_per_table=ON;" \
    && mysql -uroot -e "SET GLOBAL innodb_large_prefix=1;" \
    # Create the Dodona database.
    && mysql -uroot -e "CREATE DATABASE dodona" \
    # Create the Dodona user.
    && mysql -uroot -e "CREATE USER dodona@localhost IDENTIFIED BY 'dodona';" \
    # Grant privileges.
    && mysql -uroot -e "GRANT ALL PRIVILEGES ON dodona.* TO 'dodona'@'localhost';" \
    # Flsuh privileges.
    && mysql -uroot -e "FLUSH PRIVILEGES;" \
    # Perform database migrations.
    && bin/rails db:migrate \
    # Seed the database.
    && bin/rails db:seed \
    # Start the application.
    && bundler exec rails server -b 0.0.0.0
