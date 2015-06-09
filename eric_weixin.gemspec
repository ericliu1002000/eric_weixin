$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "eric_weixin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name          = "eric_weixin"
  spec.version       = EricWeixin::VERSION
  spec.authors       = ["刘晓琦"]
  spec.email         = ["ericliu@ikidstv.com"]
  spec.summary       = %q{微信插件}
  spec.description   = %q{快速开发微信公众账号}
  spec.homepage      = ""
  spec.license       = "MIT"


  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  spec.test_files = Dir["test/**/*"]

  spec.add_dependency "rails", "~> 4.1.4"


end