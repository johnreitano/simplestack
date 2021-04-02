# frozen_string_literal: true

namespace :db do
  desc 'Checks to see if the database exists and has loaded any tables into its schema'
  task :has_loaded_schema do
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
  rescue StandardError => e
    puts e.inspect    
    puts 'Database does not exist'
    exit 1
  else
    if ActiveRecord::Base.connection.tables.none?
      puts 'Database exists but has not loaded any tables into its schema'
      exit 1
    else
      puts 'Database exists and has loaded tables into its schema'
      exit 0
    end
  end
end
