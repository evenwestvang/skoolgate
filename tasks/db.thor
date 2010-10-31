class Db < Thor
  desc "dump_db", "Dump database"
  def dump_db
    env = ENV['RACK_ENV'] || "development"
    system("mongodump -d skoolgate_#{env} -o data")
  end

  desc "restore_db", "Restore database from development dump"
  def restore_db
    env = ENV['RACK_ENV'] || "development"
    system("mongorestore -d skoolgate_#{env} data data/nuskool_development")
  end

  no_tasks do
    def env
    end
  end

end