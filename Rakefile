# Rakefile for SimpleStack

# Copyright 2020, 2021 by John Reitano (jreitano@gmail.com)
# All rights reserved.

# This file may be distributed under an MIT style license.  See
# MIT-LICENSE for details.

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) if File.exist?(lib) && !$LOAD_PATH.include?(lib)

DOCKER_COMPOSE = "docker-compose -p auto-api"

task :up do
  sh "#{DOCKER_COMPOSE} up -d --force-recreate --remove-orphans"
end

task default: :up
