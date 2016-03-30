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

  spec.add_dependency "rails", ">= 4.1.4"

  spec.add_dependency "foundation-rails", "5.4.3"
  spec.add_dependency "jquery-ui-rails", "~>5.0.5"
  spec.add_dependency "rest-client", '1.8.0'
  spec.add_dependency "tinymce-rails"
  spec.add_dependency "will_paginate-foundation"
  spec.add_dependency "eric_tools', '~> 0.0.7"
  spec.add_dependency "exception_notification"
  spec.add_dependency "multi_xml"
  spec.add_dependency "nokogiri"

  spec.add_dependency "jquery-rails"
  spec.add_dependency "daemons"  # delayed_job 使用的延时进程
  spec.add_dependency "delayed_job_active_record"

# 生产条码\二维码, 以及两个依赖gem
  spec.add_dependency "barby"
  spec.add_dependency "chunky_png"
  spec.add_dependency "rqrcode"
end