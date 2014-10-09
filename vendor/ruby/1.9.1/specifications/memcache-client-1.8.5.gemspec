# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "memcache-client"
  s.version = "1.8.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Hodel", "Robert Cottrell", "Mike Perham"]
  s.date = "2010-07-05"
  s.description = "A Ruby library for accessing memcached."
  s.email = "mperham@gmail.com"
  s.executables = ["memcached_top"]
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.files = ["bin/memcached_top", "LICENSE.txt", "README.rdoc"]
  s.homepage = "http://github.com/mperham/memcache-client"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "A Ruby library for accessing memcached."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
