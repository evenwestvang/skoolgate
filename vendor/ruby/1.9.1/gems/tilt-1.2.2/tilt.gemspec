Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'tilt'
  s.version = '1.2.2'
  s.date = '2011-01-17'

  s.description = "Generic interface to multiple Ruby template engines"
  s.summary     = s.description

  s.authors = ["Ryan Tomayko"]
  s.email = "r@tomayko.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README.md
    Rakefile
    TEMPLATES.md
    bin/tilt
    lib/tilt.rb
    test/contest.rb
    test/markaby/locals.mab
    test/markaby/markaby.mab
    test/markaby/markaby_other_static.mab
    test/markaby/render_twice.mab
    test/markaby/scope.mab
    test/markaby/yielding.mab
    test/tilt_blueclothtemplate_test.rb
    test/tilt_buildertemplate_test.rb
    test/tilt_cache_test.rb
    test/tilt_coffeescripttemplate_test.rb
    test/tilt_compilesite_test.rb
    test/tilt_erbtemplate_test.rb
    test/tilt_erubistemplate_test.rb
    test/tilt_hamltemplate_test.rb
    test/tilt_lesstemplate_test.rb
    test/tilt_liquidtemplate_test.rb
    test/tilt_markaby_test.rb
    test/tilt_nokogiritemplate_test.rb
    test/tilt_radiustemplate_test.rb
    test/tilt_rdiscounttemplate_test.rb
    test/tilt_rdoctemplate_test.rb
    test/tilt_redclothtemplate_test.rb
    test/tilt_sasstemplate_test.rb
    test/tilt_stringtemplate_test.rb
    test/tilt_template_test.rb
    test/tilt_test.rb
    tilt.gemspec
  ]
  # = MANIFEST =

  s.default_executable = 'tilt'
  s.executables = ['tilt']

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}
  s.add_development_dependency 'contest'
  s.add_development_dependency 'builder'
  s.add_development_dependency 'erubis'
  s.add_development_dependency 'haml', '>= 2.2.11'
  s.add_development_dependency 'rdiscount'
  s.add_development_dependency 'liquid'
  s.add_development_dependency 'less'
  s.add_development_dependency 'radius'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'markaby'
  s.add_development_dependency 'coffee-script'

  s.extra_rdoc_files = %w[COPYING]

  s.has_rdoc = true
  s.homepage = "http://github.com/rtomayko/tilt/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Tilt", "--main", "Tilt"]
  s.require_paths = %w[lib]
  s.rubyforge_project = 'wink'
  s.rubygems_version = '1.1.1'
end
