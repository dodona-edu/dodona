# Set the base image. We cannot use alpine as long as we don't get rid of 
# therubyracer.
FROM ruby:2.7.2-slim

# Tag the repository.
LABEL org.opencontainers.image.source https://github.com/dodona-edu/dodona

################################################################################
################################### PACKAGES ###################################
################################################################################

# Install system packages.
RUN apt-get update
RUN apt-get -y install --no-install-recommends \ 
    build-essential curl git libmariadb-dev

# Install NodeJS.
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt-get -y install --no-install-recommends nodejs
RUN npm install -g yarn

# Install common ruby packages to leverage docker caching.
RUN gem install bundler:2.1.4

# Create a directory to store the application in.
RUN mkdir /app
WORKDIR /app

# Copy the dependency files.
COPY Gemfile /app
COPY Gemfile.lock /app
COPY package.json /app
COPY yarn.lock /app

# Install the dependencies.
RUN bundler install --without production staging test --jobs 4 --retry 3
RUN yarn install

################################################################################
################################# APPLICATION ##################################
################################################################################

# Copy the rest of the application into the container.
COPY . /app

# Patch the database host. This is needed because the localhost socket does not
# exist on this container.
RUN sed -i 's+localhost+database+g' /app/config/database.yml
RUN sed -i 's+username: dodona+username: root+g' /app/config/database.yml

# Patch the seeds, use a public judge and clone over https.
RUN sed -i 's+git@github.com:dodona-edu/+https://github.com/dodona-edu/+g' \
    /app/db/seeds.rb
RUN sed -i 's/judge-pythia.git/judge-java12.git/' /app/db/seeds.rb
RUN sed -i 's/20\.times/2.times/g' /app/db/seeds.rb

# Set the initialisation script.
RUN chmod +x /app/docker-entrypoint.sh
ENTRYPOINT /app/docker-entrypoint.sh

# Expose the webserver to the outside world.
EXPOSE 3000

################################################################################
#################################### CLEANUP ###################################
################################################################################

# Remove build dependencies.
RUN apt-get purge -y --auto-remove build-essential