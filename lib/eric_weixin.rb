require "eric_weixin/version"
# require "eric_weixin/app/moudles/ip"
require "rest-client"

#加载model
require File.dirname(__FILE__) + '/eric_weixin/app/model/access_token.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/article.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/article_news.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/news.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/public_account.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/reply_message_rule.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/template_message_log.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/weixin_user.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/message_log.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/two_dimension_code.rb'
#todo  邹改了


#加载moudle
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/reply_message.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/mult_customer.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/snsapi.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/ip.rb'


#加载controller
require File.dirname(__FILE__) + '/eric_weixin/app/controllers/weixin/weixin_controller'


module EricWeixin
  # 把gem目录放作为视图目录
  ActionController::Base.append_view_path(File.dirname(__FILE__) + '/eric_weixin/app/views')



end
__END__
cd && cd /Users/zig/dev/work/eric_weixin && rm -rf *.gem && gem build eric_weixin.gemspec &&
cd /Users/zig/dev/work/ddc-2015-05-31 && gem uninstall eric_weixin && gem install ../eric_weixin/eric_weixin-0.0.10.gem --local
