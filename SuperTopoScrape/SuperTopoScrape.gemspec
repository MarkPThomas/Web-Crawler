# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "NAME"
  spec.version       = '1.0'
  spec.authors       = ["Mark Thomas"]
  spec.email         = ["markums@gmail.com"]
  spec.summary       = %q{One-time scraper for SuperTopo}
  spec.description   = %q{Scrapes a variety of data from http://www.supertopo.com based on links found in my personal profile. In addition to getting data from submitted trip reports, this gem also gets an updated hits count for each trip report. A later version will be created to just scrape the latest data in order to keep my personal website in sync on relevant data.}
  spec.homepage      = "http://www.MarkPThomas.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/NAME.rb']
  spec.executables   = ['bin/NAME']
  spec.test_files    = ['tests/test_NAME.rb']
  spec.require_paths = ["lib"]
end