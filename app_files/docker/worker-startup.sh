#!/bin/bash

set -e
# set -x

wait-for-it database:5432 -t 60
bundle exec rails jobs:work

