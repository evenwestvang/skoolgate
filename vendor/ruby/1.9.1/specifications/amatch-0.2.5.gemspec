# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "amatch"
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2009-09-25"
  s.description = "Amatch is a library for approximate string matching and searching in strings.\nSeveral algorithms can be used to do this, and it's also possible to compute a\nsimilarity metric number between 0.0 and 1.0 for two given strings.\n"
  s.email = "flori@ping.de"
  s.executables = ["agrep.rb"]
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = ["README", "ext/amatch.c", "lib/amatch/version.rb"]
  s.files = ["bin/agrep.rb", "README", "ext/amatch.c", "lib/amatch/version.rb", "ext/extconf.rb"]
  s.homepage = "http://amatch.rubyforge.org"
  s.rdoc_options = ["--main", "README", "--title", "amatch - Approximate Matching"]
  s.require_paths = ["lib", "ext", "lib"]
  s.rubyforge_project = "amatch"
  s.rubygems_version = "1.8.23"
  s.summary = "Approximate String Matching library"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
