#!/usr/bin/env bash

set -x

rails new --skip-spring --skip-sprockets -m template.rb $@
cd $1
rails server -p 4000
