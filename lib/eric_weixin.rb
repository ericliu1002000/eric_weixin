require "eric_weixin/version"

require File.dirname(__FILE__) + '/eric_weixin/app/model/access_token.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/article.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/article_news.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/news.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/public_account.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/reply_message_rule.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/model/weixin_user.rb'
require File.dirname(__FILE__) + '/eric_weixin/reply_message.rb'
require File.dirname(__FILE__) + '/eric_weixin/app/controllers/weixin/weixin_controller'


module EricWeixin
  # 把gem目录放作为视图目录
  ActionController::Base.append_view_path(File.dirname(__FILE__) + '/eric_weixin/app/views')

  #获取重定向的URI
  #参数1:   url      #业务URL，即最终需要跳转到的url,域名中的主机名称可选，可以写 'www.baidu.com/xxx', 也可以写 '/xxx'。 这里主要用于重定向。
  #参数2:   app_id   #公众账号app_id
  #参数3:   schema_host 当前项目的域名(包含http://)：如http://www.baidu.com
  #可选参数4: state
  #示例：get_snsapi_uri url:'/weixin/service1/ddd?a=1', app_id: 'wx4564afc37fac0ebf', schema_host: "http://lxq.mdcc.com"
  def get_snsapi_url options
    require 'base64'
    p_zhongzhuan = []
    p_zhongzhuan_host_path = "#{options[:schema_host]}/weixin/snsapi"
    p_zhongzhuan << ["weixin_app_id", options[:app_id]]
    p_zhongzhuan << ["url", Base64.encode64(options[:url])]
    p_zhongzhuan = URI.encode_www_form p_zhongzhuan
    p_zhongzhuan = CGI::unescape p_zhongzhuan
    p_zhongzhuan_url = [p_zhongzhuan_host_path, p_zhongzhuan].join('?')

    p_host_and_path = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    p = []
    p << ['appid', options[:app_id]]
    p << ["redirect_uri", CGI::escape(p_zhongzhuan_url)]
    p << ['response_type', 'code']
    p << ['scope', 'snsapi_base']
    p << ['state', "#{options[:state]||'abc'}"]
    p = URI.encode_www_form p
    p = CGI::unescape p
    p_url = [p_host_and_path, "#{p}#wechat_redirect"].join '?'
    p_url
  end


end
