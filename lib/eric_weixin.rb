require "eric_weixin/version"
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
require File.dirname(__FILE__) + '/eric_weixin/app/model/customs_service_record.rb'

#加载moudle
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/reply_message.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/mult_customer.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/moudles/snsapi.rb'


#加载controller
require File.dirname(__FILE__) + '/eric_weixin/app/controllers/weixin/weixin_controller'


module EricWeixin
  # 把gem目录放作为视图目录
  ActionController::Base.append_view_path(File.dirname(__FILE__) + '/eric_weixin/app/views')



end
