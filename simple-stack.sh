#!/usr/bin/env bash

set -x

rails new --skip-spring --skip-sprockets --database=postgresql -m template.rb $@
cd $1
rails server -p 4000

# target_path=$1
# mkdir -p ${target_path}/tmp
# touch ${target_path}/tmp/caching-dev.txt
# cp -R ./ruby $target_path/
# rails new --webpack=stilmulus --skip-spring --skip-sprockets --database=postgresql -m template.rb $@
# cd ${target_path}
# rails server -p 4000
