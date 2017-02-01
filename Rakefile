require 'rubygems'

db = "sqlite://database/inventory.db"

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
