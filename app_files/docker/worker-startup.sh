#!/bin/bash

set -e
# set -x

./config/docker/wait-for-mysql-server.sh

bundle exec rails jobs:work

