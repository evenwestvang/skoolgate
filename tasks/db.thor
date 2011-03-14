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

  desc "create_index", "Index DB"
  def create_indexes
    require './environment'
    [County, Municipality, School].each { |m| puts m.send(:create_indexes) }
  end
end