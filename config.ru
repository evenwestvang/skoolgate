require './app'

FileUtils.mkdir_p 'log' unless File.exists?('log')


run Sinatra::Application