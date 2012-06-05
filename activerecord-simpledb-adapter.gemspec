$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = %q{activerecord-simpledb-adapter}
  s.version       = "0.4.12"
  s.authors       = ["Ilia Ablamonov", "Alex Gorkunov", "Cloud Castle Inc."]
  s.email         = %q{ilia@flamefork.ru}
  s.licenses      = ["MIT"]
  s.homepage      = %q{http://www.github.com/gorkunov/consular-another-gnome-terminal}
  s.summary       = %q{Gnome Terminal support for Consular (without using xdotool)}
  s.description   = %q{Gnome Terminal support for Consular without emulation keyboard events}
  s.homepage      = %q{http://github.com/cloudcastle/activerecord-simpledb-adapter}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<aws>)
  s.add_runtime_dependency(%q<activerecord>, ["~> 3.0.9"])
  s.add_runtime_dependency(%q<uuidtools>)
  s.add_development_dependency(%q<awesome_print>)
  s.add_development_dependency(%q<rspec>)
  s.add_development_dependency(%q<rails>, ["~> 3.0.9"])
  s.add_development_dependency(%q<genspec>)
  s.add_development_dependency(%q<thor>)
end
