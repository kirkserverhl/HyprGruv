# -*- encoding: utf-8 -*-
# stub: clocale 0.0.4 ruby lib
# stub: ext/clocale/extconf.rb

Gem::Specification.new do |s|
  s.name = "clocale".freeze
  s.version = "0.0.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Claudio Bley".freeze]
  s.date = "2018-08-11"
  s.email = ["claudio.bley@gmail.com".freeze]
  s.extensions = ["ext/clocale/extconf.rb".freeze]
  s.files = ["ext/clocale/extconf.rb".freeze]
  s.homepage = "https://github.com/avdv/clocale".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.7".freeze
  s.summary = "A Ruby gem that wraps C locale functions.".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<codecov>.freeze, ["~> 0.1.10".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.58".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.27".freeze])
  s.add_development_dependency(%q<rubygems-tasks>.freeze, ["~> 0.2".freeze])
end
