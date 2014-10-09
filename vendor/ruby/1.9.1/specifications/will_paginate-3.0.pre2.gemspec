# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "will_paginate"
  s.version = "3.0.pre2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mislav Marohni\u{c4}\u{87}"]
  s.date = "2010-02-05"
  s.description = "The will_paginate library provides a simple, yet powerful and extensible API for pagination and rendering of page links in web application templates."
  s.email = "mislav.marohnic@gmail.com"
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "CHANGELOG.rdoc"]
  s.files = ["README.rdoc", "LICENSE", "CHANGELOG.rdoc"]
  s.homepage = "http://github.com/mislav/will_paginate/wikis"
  s.rdoc_options = ["--main", "README.rdoc", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Adaptive pagination plugin for web frameworks and other applications"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
