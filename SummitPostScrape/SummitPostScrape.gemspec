# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "SummitPostScrape"
  spec.version       = '1.0'
  spec.authors       = ["Mark Thomas"]
  spec.email         = ["markums@gmail.com"]
  spec.summary       = %q{Short summary of your project}
  spec.description   = %q{Longer description of your project.}
  spec.homepage      = "http://www.MarkPThomas.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/SummitPostScrape.rb']
  spec.executables   = ['bin/SummitPostScrape']
  spec.test_files    = ['tests/test_SummitPostScrape.rb']
  spec.require_paths = ["lib"]
end