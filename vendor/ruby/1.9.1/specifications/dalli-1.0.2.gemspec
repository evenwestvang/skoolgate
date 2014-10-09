# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "dalli"
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mike Perham"]
  s.date = "2011-02-03"
  s.description = "High performance memcached client for Ruby"
  s.email = "mperham@gmail.com"
  s.homepage = "http://github.com/mperham/dalli"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "High performance memcached client for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<rails>, [">= 3.0.1"])
      s.add_development_dependency(%q<memcache-client>, [">= 1.8.5"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<rails>, [">= 3.0.1"])
      s.add_dependency(%q<memcache-client>, [">= 1.8.5"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<rails>, [">= 3.0.1"])
    s.add_dependency(%q<memcache-client>, [">= 1.8.5"])
  end
end
