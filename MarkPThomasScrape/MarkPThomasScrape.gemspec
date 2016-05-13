# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "MarkPThomasScrape"
  spec.version       = '1.0'
  spec.authors       = ["Mark Thomas"]
  spec.email         = ["markums@gmail.com"]
  spec.summary       = %q{One-time scraper for my original personal website.}
  spec.description   = %q{Scrapes a variety of data from http://www.markpthomas.com based on links found in the navigation sidebar. Considered a one-off run to get all current data to convert over to my new site.}
  spec.homepage      = "http://www.MarkPThomas.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/MarkPThomasScrape.rb']
  spec.executables   = ['bin/MarkPThomasScrape']
  spec.test_files    = ['tests/test_MarkPThomasScrape.rb']
  spec.require_paths = ["lib"]
end