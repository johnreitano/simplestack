#!/bin/bash

set -e

DB_HOST=$(echo $DB_SECRETS | jq -r '.host')
DB_PORT=$(echo $DB_SECRETS | jq -r '.port')
wait-for-it $DB_HOST:$DB_PORT --strict --timeout=30 -- echo 'mysql is available'
