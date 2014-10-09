# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mongoid"
  s.version = "2.0.0.rc.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Durran Jordan"]
  s.date = "2011-01-29"
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."
  s.email = ["durran@gmail.com"]
  s.homepage = "http://mongoid.org"
  s.require_paths = ["lib"]
  s.rubyforge_project = "mongoid"
  s.rubygems_version = "1.8.23"
  s.summary = "Elegant Persistance in Ruby for MongoDB."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>, ["~> 3.0"])
      s.add_runtime_dependency(%q<tzinfo>, ["~> 0.3.22"])
      s.add_runtime_dependency(%q<will_paginate>, ["~> 3.0.pre"])
      s.add_runtime_dependency(%q<mongo>, ["~> 1.2"])
      s.add_development_dependency(%q<bson_ext>, ["~> 1.2"])
      s.add_development_dependency(%q<mocha>, ["= 0.9.8"])
      s.add_development_dependency(%q<rspec>, ["~> 2.4"])
      s.add_development_dependency(%q<watchr>, ["= 0.6"])
    else
      s.add_dependency(%q<activemodel>, ["~> 3.0"])
      s.add_dependency(%q<tzinfo>, ["~> 0.3.22"])
      s.add_dependency(%q<will_paginate>, ["~> 3.0.pre"])
      s.add_dependency(%q<mongo>, ["~> 1.2"])
      s.add_dependency(%q<bson_ext>, ["~> 1.2"])
      s.add_dependency(%q<mocha>, ["= 0.9.8"])
      s.add_dependency(%q<rspec>, ["~> 2.4"])
      s.add_dependency(%q<watchr>, ["= 0.6"])
    end
  else
    s.add_dependency(%q<activemodel>, ["~> 3.0"])
    s.add_dependency(%q<tzinfo>, ["~> 0.3.22"])
    s.add_dependency(%q<will_paginate>, ["~> 3.0.pre"])
    s.add_dependency(%q<mongo>, ["~> 1.2"])
    s.add_dependency(%q<bson_ext>, ["~> 1.2"])
    s.add_dependency(%q<mocha>, ["= 0.9.8"])
    s.add_dependency(%q<rspec>, ["~> 2.4"])
    s.add_dependency(%q<watchr>, ["= 0.6"])
  end
end
