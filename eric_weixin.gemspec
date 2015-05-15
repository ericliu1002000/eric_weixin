# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eric_weixin/version'

Gem::Specification.new do |spec|
  spec.name          = "eric_weixin"
  spec.version       = EricWeixin::VERSION
  spec.authors       = ["刘晓琦"]
  spec.email         = ["ericliu@ikidstv.com"]
  spec.summary       = %q{微信插件}
  spec.description   = %q{微信插件}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", '~> 0'
  spec.add_development_dependency 'nokogiri', '~> 0'
  spec.add_development_dependency 'rest-client', '~> 0'
  spec.add_development_dependency 'activerecord', '~> 4.1', '>= 4.1.4'
  spec.add_development_dependency 'rails', '~> 4.1', '>= 4.1.4'
  spec.add_development_dependency 'actionpack', '~> 4.1', '>= 4.1.4'
  spec.add_development_dependency 'activesupport', '~> 4.1', '>= 4.1.4'
  spec.add_development_dependency 'actionview', '~> 4.1', '>= 4.1.4'
  spec.add_development_dependency 'eric_tools', '~> 0.0', '>= 0.0.4'

end
