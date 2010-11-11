class Db < Thor
  desc "dump", "Dump database"
  def dump
    env = ENV['RACK_ENV'] || "development"
    system("mongodump -d skoolgate_#{env} -o data")
  end

  desc "restore", "Restore database from development dump"
  def restore
    env = ENV['RACK_ENV'] || "development"
    system("mongorestore -d skoolgate_#{env} data/nuskool_development")
  end

end