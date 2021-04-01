#!/bin/bash

set -e
set -x # TODO: delete this line once this code is shown to work in production

./config/docker/wait-for-mysql-server.sh

bundle exec rails jobs:work

