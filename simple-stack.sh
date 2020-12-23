#!/usr/bin/env bash

rails new --skip-spring --skip-sprockets --database=postgresql -m template.rb $@
