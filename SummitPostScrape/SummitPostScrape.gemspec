# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "SummitPostScrape"
  spec.version       = '1.0'
  spec.authors       = ["Mark Thomas"]
  spec.email         = ["markums@gmail.com"]
  spec.summary       = %q{One-time scraper for SummitPost}
  spec.description   = %q{Scrapes a variety of data from http://www.summitpost.org based on links found in my personal profile. Considered a one-off run to get all current data. A later version will be created to just scrape the latest data in order to keep my personal website in sync on relevant data.}
  spec.homepage      = "http://www.MarkPThomas.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/SummitPostScrape.rb']
  spec.executables   = ['bin/SummitPostScrape']
  spec.test_files    = ['tests/test_SummitPostScrape.rb']
  spec.require_paths = ["lib"]
end