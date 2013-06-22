# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "neography-batch"
  s.version     = "1.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = "Jorg Jenni"
  s.email       = "jorg.jenni@jennius.co.uk"
  s.homepage    = "https://github.com/Enceradeira/neography-batch"
  s.summary     = "Composable neography-batches"
  s.description = "Makes neography-batches better composable (for neography-batches see https://github.com/maxdemarzi/neography/wiki/Batch)"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "neography", ">= 1.0.6"
  s.add_development_dependency "rspec", ">= 2.11"
  s.add_development_dependency "rake", ">= 0.8.7"
end
