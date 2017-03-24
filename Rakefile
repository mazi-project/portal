require 'rubygems'
require 'fileutils'

db = "sqlite://database/inventory.db"

desc "Run migrations ('rake db:migrate' to run all migrations, 'rake db:migrate[10]'' to run the 10th migration, 'rake db:migrate[0] to reset the db)"
task :init do
  puts "Initializing"
  unless File.directory?("/etc/mazi")
    puts "Folder '/etc/mazi' does not exist. Generating."
    FileUtils.mkdir_p("/etc/mazi")
  end

  unless File.directory?("/etc/mazi/snapshots")
    puts "Folder '/etc/mazi/snapshots' does not exist. Generating."
    FileUtils.mkdir_p("/etc/mazi/snapshots")
  end

  unless File.exist?("/etc/mazi/config.yml")
    puts "File '/etc/mazi/config.yml' does not exist. Generating."
    FileUtils.cp 'etc/config.yml', '/etc/mazi/config.yml'
  end

  unless File.exist?("/etc/mazi/snapshots/default.yml")
    puts "File '/etc/mazi/snapshots/default.yml' does not exist. Generating."
    FileUtils.cp 'etc/config.yml', '/etc/mazi/snapshots/default.yml'
  end

  unless File.exist?("/etc/mazi/snapshots/default.net")
    puts "File '/etc/mazi/snapshots/default.net' does not exist. Generating."
    FileUtils.touch '/etc/mazi/snapshots/default.net'
  end

  puts "done!"
end


namespace :db do
  desc "Run migrations ('rake db:migrate' to run all migrations, 'rake db:migrate[10]'' to run the 10th migration, 'rake db:migrate[0] to reset the db)"
  task :migrate, [:version] do |t, args|
    desc "Migrate the db"
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(db)
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "database/migrations", target: args[:version].to_i)
      puts "done!"
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "database/migrations")
      puts "done!"
    end
  end
  task :reset do |t|
    desc "Migrate the db"
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(db)
    puts "Reseting the database"
    Sequel::Migrator.run(db, "database/migrations", target: 0)
    puts "done!"
  end
end
