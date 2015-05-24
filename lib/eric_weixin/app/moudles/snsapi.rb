module EricWeixin::Snsapi

  # 获取snsapi_base授权的完整链接.
  # 每次更新菜单调整链接都需要花时间把链接整理好，再URLEncode之类的，很烦有木不？
  # 来这里吧，输入几个无脑参数，分分钟获取到全链接，方便、快速、搞得定。
  # 善意提醒：别说这里有个坑，这个函数生成的链接，是需要配合本Gem的Controller、action来使用的。
  # ===参数说明
  # * url      #业务URL，即最终需要跳转到的url,域名中的主机名称可选，可以写 'www.baidu.com/xxx', 也可以写 '/xxx'。 这个地址用于最后重定向。
  # * app_id   #公众账号app_id
  # * schema_host 当前项目的域名(包含http://)：如http://www.baidu.com
  # * state 这个参数可以直接带到业务页面。
  # ===调用示例
  #  EricWeixin::Snsapi.get_snsapi_base_url url:'/weixin/service1/ddd?a=1', app_id: 'wx51729870d9012531', schema_host: "http://lxq.mdcc.club"
  def self.get_snsapi_base_url options
    require 'base64'
    p_zhongzhuan = []
    p_zhongzhuan_host_path = "#{options[:schema_host]}/weixin/snsapi"
    p_zhongzhuan << ["weixin_app_id", options[:app_id]]
    p_zhongzhuan << ["url", Base64.encode64(options[:url]).gsub(/\n/,'')]
    p_zhongzhuan = URI.encode_www_form p_zhongzhuan
    p_zhongzhuan = CGI::unescape p_zhongzhuan
    p_zhongzhuan_url = [p_zhongzhuan_host_path, p_zhongzhuan].join('?')

    p_host_and_path = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    p = []
    p << ['appid', options[:app_id]]
    p << ['redirect_uri', CGI::escape(p_zhongzhuan_url)]
    p << ['response_type', 'code']
    p << ['scope', 'snsapi_base']
    p << ['state', "#{options[:state]||'abc'}"]
    p = URI.encode_www_form p
    p = CGI::unescape p
    p_url = [p_host_and_path, "#{p}#wechat_redirect"].join '?'
    p_url
  end



  # 获取snsapi_userinfo授权的完整链接.
  # 每次更新菜单调整链接都需要花时间把链接整理好，再URLEncode之类的，很烦有木不？
  # 来这里吧，输入几个无脑参数，分分钟获取到全链接，方便、快速、搞得定。
  # 善意提醒：别说这里有个坑，这个函数生成的链接，是需要配合本Gem的Controller、action来使用的。
  # ===参数说明
  # * url      #业务URL，即最终需要跳转到的url,域名中的主机名称可选，可以写 'www.baidu.com/xxx', 也可以写 '/xxx'。 这个地址用于最后重定向。
  # * app_id   #公众账号app_id
  # * schema_host 当前项目的域名(包含http://)：如http://www.baidu.com
  # * state 这个参数可以直接带到业务页面。
  # ===调用示例
  #  EricWeixin::Snsapi.get_snsapi_userinfo_url url:'/weixin/service1/ddd?a=1', app_id: 'wx51729870d9012531', schema_host: "http://lxq.mdcc.club"
  def self.get_snsapi_userinfo_url options
    require 'base64'
    p_zhongzhuan = []
    p_zhongzhuan_host_path = "#{options[:schema_host]}/weixin/snsuserinfo"
    p_zhongzhuan << ["weixin_app_id", options[:app_id]]
    p_zhongzhuan << ["url", Base64.encode64(options[:url]).gsub(/\n/,'')]
    p_zhongzhuan = URI.encode_www_form p_zhongzhuan
    p_zhongzhuan = CGI::unescape p_zhongzhuan
    p_zhongzhuan_url = [p_zhongzhuan_host_path, p_zhongzhuan].join('?')

    p_host_and_path = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    p = []
    p << ['appid', options[:app_id]]
    p << ["redirect_uri", CGI::escape(p_zhongzhuan_url)]
    p << ['response_type', 'code']
    p << ['scope', 'snsapi_userinfo']
    p << ['state', "#{options[:state]||'state'}"]
    p = URI.encode_www_form p
    p = CGI::unescape p
    p_url = [p_host_and_path, "#{p}#wechat_redirect"].join '?'
    p_url
  end

end
