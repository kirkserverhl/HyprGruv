# -*- encoding: utf-8 -*-
# stub: colorls 1.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "colorls".freeze
  s.version = "1.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Athitya Kumar".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-07-07"
  s.email = ["athityakumar@gmail.com".freeze]
  s.executables = ["colorls".freeze]
  s.files = ["exe/colorls".freeze]
  s.homepage = "https://github.com/athityakumar/colorls".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\n  *******************************************************************\n    Changes introduced in colorls\n\n    Sort by dirs  : -sd flag has been renamed to --sd\n    Sort by files : -sf flag has been renamed to --sf\n    Git status    : -gs flag has been renamed to --gs\n\n    Clubbed flags : `colorls -ald` works\n    Help menu     : `colorls -h` provides all possible flag options\n\n    Tab completion enabled for flags\n\n    -t flag : Previously short for --tree, has been re-allocated to sort results by time\n    -r flag : Previously short for --report, has been re-allocated to reverse sort results\n\n    Man pages have been added. Checkout `man colorls`.\n\n  *******************************************************************\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.22".freeze
  s.summary = "A Ruby CLI gem that beautifies the terminal's ls command, with color and font-awesome icons.".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.7".freeze])
  s.add_runtime_dependency(%q<clocale>.freeze, ["~> 0".freeze])
  s.add_runtime_dependency(%q<filesize>.freeze, ["~> 0".freeze])
  s.add_runtime_dependency(%q<manpages>.freeze, ["~> 0".freeze])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<unicode-display_width>.freeze, [">= 1.7".freeze, "< 3.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<codecov>.freeze, ["~> 0.1".freeze])
  s.add_development_dependency(%q<diffy>.freeze, ["= 3.4.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.1".freeze])
  s.add_development_dependency(%q<ronn>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.50.1".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.17.1".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.5".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.20.0".freeze])
  s.add_development_dependency(%q<rubygems-tasks>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22.0".freeze])
end
