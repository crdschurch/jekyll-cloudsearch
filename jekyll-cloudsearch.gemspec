lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-cloudsearch/version'

Gem::Specification.new do |s|
  s.name        = 'jekyll-cloudsearch'
  s.version     = Jekyll::Cloudsearch::VERSION
  s.licenses    = ['BSD-3']
  s.summary     = "Jekyll integration for AWS Cloudsearch"
  s.authors     = ["Ample"]
  s.email       = 'taylor@helloample.com'
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]
  s.add_dependency 'jekyll'
  s.add_dependency 'aws-sdk-cloudsearchdomain'
  s.add_dependency 'nokogiri'
  s.add_dependency 'contentful-management', '~> 1.10.1'
end