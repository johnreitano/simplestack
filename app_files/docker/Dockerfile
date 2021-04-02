FROM ruby:2.7.2-buster

RUN apt-get update -y && apt-get install -y wait-for-it jq

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y yarn

# Pass this in via build-args, e.g. "--build-arg RAILS_ENV=production"
ARG RAILS_ENV
ARG RAILS_MASTER_KEY

# Setup environment variables that will be available to the instance
ENV HOME /root
ENV BASE_DIR /home/app
ENV APP_HOME $BASE_DIR/core
ENV GEM_HOME $BASE_DIR/gems

# put the gems in a separate directory (outside of the app)
# so they won't get rebuilt anytime the app's code is changed
# https://blog.carbonfive.com/2015/03/17/docker-rails-docker-compose-together-in-your-development-workflow/
RUN mkdir -p $BASE_DIR && \
    mkdir -p $GEM_HOME && \
    mkdir -p $APP_HOME && \
    mkdir -p $APP_HOME/tmp/sockets && \
    mkdir -p $APP_HOME/tmp/pids && \
    mkdir -p $APP_HOME/tmp/log

RUN gem update --system && \
    gem install bundler && \
    bundle -v

# Copy over Gemfile first so that changes to other app files don't trigger re-running of bundle install 
WORKDIR $GEM_HOME
COPY Gemfile Gemfile.lock $GEM_HOME/
RUN bundle install

# cleanup
RUN rm -rf /var/lib/apt/lists/*

# Copy the main application.
WORKDIR $APP_HOME

RUN if [ ! -e yarn.lock ]; then \
        yarn install && yarn upgrade; \
    fi; \
    yarn install # --check files

EXPOSE 4000

CMD ["docker/website-startup.sh"]
