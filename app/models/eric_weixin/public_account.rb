class EricWeixin::PublicAccount < ActiveRecord::Base

  require "rest-client"
  self.table_name = "weixin_public_accounts"
  has_many :weixin_users, :class_name => 'WeixinUser', foreign_key: "weixin_public_account_id"
  has_many :two_dimension_codes, :class_name => 'TwoDimensionCode', foreign_key: "weixin_public_account_id"
  has_one :access_token, :class_name => 'AccessToken', foreign_key: "public_account_id"
  has_many :customs_service_records, class_name: 'CustomsServiceRecord', foreign_key: "weixin_public_account_id"
  has_many :redpacks, foreign_key: "weixin_public_account_id"
  has_many :orders, class_name: "::EricWeixin::PublicAccount", foreign_key: 'weixin_public_account_id'

  #根据微信号名称获取微信账号相关信息
  # ::EricWeixin::PublicAccount.get_public_account_by_name 'dfxt'
  def self.get_public_account_by_name name
    accounts = ::EricWeixin::PublicAccount.where name: name
    return nil if accounts.blank?
    accounts[0]
  end

  #
  # def self.get_secret app_id
  #   account = ::EricWeixin::PublicAccount.where(weixin_app_id: app_id).first
  #   account.weixin_secret_key
  # end

  # 获取用户基本信息.
  # ===参数说明
  # * openid   #用户openid
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.get_user_data_from_weixin_api 'osyUtswoeJ9d7p16RdpC5grOeukQ'
  def get_user_data_from_weixin_api openid
    ::EricWeixin::WeixinUser.get_user_data_from_weixin_api self.id, openid
  end

  # 获取微信菜单.
  # ===参数说明
  # * 无。
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.weixin_menus
  def weixin_menus
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.id
    response = RestClient.get "https://api.weixin.qq.com/cgi-bin/menu/get?access_token=#{token}"
    response = JSON.parse response.body
    response['menu']
  end

  # 创建新的公众号菜单.
  # ===参数说明
  # * menu_json   #要添加的公众号菜单 json 内容
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.create_menu '{
  # "button":[
  #     {
  #         "name":"俱乐部2",
  #     "sub_button":[
  #
  #     {
  #         "type":"click",
  #     "name":"节目介绍",
  #     "key":"V1001_PROGRAMME_INTRODUCTION"
  # }]
  # },
  #     {
  #         "type":"view",
  #     "name":"创意社区",
  #     "url":"http://m.wsq.qq.com/264164362"
  # },
  #     {
  #         "name":"辣妈奶爸",   13818518038 余老师
  #     "sub_button":[
  #     {
  #         "type":"click",
  #     "name":"百家言",
  #     "key":"V1001_BAIJIAYAN"
  # },
  #     {
  #         "type":"view",
  #     "name":"辣妈养成记",
  #     "url":"http://m.wsq.qq.com/264164362/t/32"
  # },
  #     {
  #         "type":"view",
  #     "name":"奶爸集中营4",
  #     "url":"http://m.wsq.qq.com/264164362/t/35"
  # }]
  # }]
  # }'
  def create_menu menu_json
    ::EricWeixin::PublicAccount.transaction do
      self.menu_json = menu_json
      self.save!
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.id
      response = RestClient.post "https://api.weixin.qq.com/cgi-bin/menu/create?access_token=#{token}", menu_json
      response = JSON.parse response.body
      BusinessException.raise response["errmsg"] if response["errcode"].to_i!=0
      pp response
      return 0
    end
  end

  # 更新数据库现有的微信用户信息,用了微信的批量获取用户数据的接口
  # ===参数说明
  # 无
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.update_users
  def update_users
    openids = self.weixin_users.pluck(:openid, :language)
    index = 0
    while index <= openids.count
      params = {}
      openid_arr = []
      openids[index..index+99].each do |op|
        openid_arr << {
            :openid => op[0],
            :lang => op[1]
        }
      end
      index += 100
      params[:user_list] = openid_arr
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.id
      response = RestClient.post "https://api.weixin.qq.com/cgi-bin/user/info/batchget?access_token=#{token}", params
      response = JSON.parse response.body
      response["user_info_list"].each do |user_info|
        user = EricWeixin::WeixinUser.find_or_create_by(openid: user_info["openid"], weixin_public_account_id: self.id)
        if user_info["subscribe"] == 1
          user_params = user_info.select{|k,v|["subscribe",
                                               "openid",
                                               "nickname",
                                               "sex",
                                               "language",
                                               "city",
                                               "province",
                                               "country",
                                               "headimgurl",
                                               "subscribe_time",
                                               "remark"].include?(k) && !v.blank?}
          user.update_attributes user_params
        else
          user.update_attributes subscribe: 0
        end
      end
    end unless openids.count == 0
  end

  # 获取用户列表，并把最新的用户信息存到数据库.
  # ===参数说明
  # * next_openid   #拉取列表的后一个用户的 next_openid，用户列表未拉取完时存在。
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.rebuild_users
  def rebuild_users next_openid = nil
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.id
    response = if next_openid.blank?
                 RestClient.get "https://api.weixin.qq.com/cgi-bin/user/get?access_token=#{token}"
               else
                 RestClient.get "https://api.weixin.qq.com/cgi-bin/user/get?access_token=#{token}&next_openid=#{next_openid}"
               end
    response = JSON.parse response.body
    if response["count"].to_i > 0
      response["data"]["openid"].each do |openid|
        ::EricWeixin::WeixinUser.create_weixin_user self.id, openid
      end
      tmp_next_openid = response["next_openid"]
      self.rebuild_users tmp_next_openid unless tmp_next_openid.blank?
    end
  end

  # 获取用户列表，并把最新的用户信息存到数据库.
  # ===参数说明
  # * next_openid   #拉取列表的后一个用户的 next_openid，用户列表未拉取完时存在。
  # ===调用示例
  # ::EricWeixin::PublicAccount.first.rebuild_users_simple
  def rebuild_users_simple next_openid = nil
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.id
    response = if next_openid.blank?
                 RestClient.get "https://api.weixin.qq.com/cgi-bin/user/get?access_token=#{token}"
               else
                 RestClient.get "https://api.weixin.qq.com/cgi-bin/user/get?access_token=#{token}&next_openid=#{next_openid}"
               end
    response = JSON.parse response.body
    if response["count"].to_i > 0
      response["data"]["openid"].each do |openid|
        users = ::EricWeixin::WeixinUser.where openid: openid
        if users.blank?
            ::EricWeixin::WeixinUser.create_weixin_user self.id, openid
        end
      end
      tmp_next_openid = response["next_openid"]
      self.rebuild_users_simple tmp_next_openid unless tmp_next_openid.blank?
    end
  end


  GLOBAL_CODES = {
      -1 => "系统繁忙",
      0 => "请求成功",
      40001 => "获取access_token时AppSecret错误，或者access_token无效",
      40002 => "不合法的凭证类型",
      40003 => "不合法的OpenID",
      40004 => "不合法的媒体文件类型",
      40005 => "不合法的文件类型",
      40006 => "不合法的文件大小",
      40007 => "不合法的媒体文件id",
      40008 => "不合法的消息类型",
      40009 => "不合法的图片文件大小",
      40010 => "不合法的语音文件大小",
      40011 => "不合法的视频文件大小",
      40012 => "不合法的缩略图文件大小",
      40013 => "不合法的APPID",
      40014 => "不合法的access_token",
      40015 => "不合法的菜单类型",
      40016 => "不合法的按钮个数",
      40017 => "不合法的按钮个数",
      40018 => "不合法的按钮名字长度",
      40019 => "不合法的按钮KEY长度",
      40020 => "不合法的按钮URL长度",
      40021 => "不合法的菜单版本号",
      40022 => "不合法的子菜单级数",
      40023 => "不合法的子菜单按钮个数",
      40024 => "不合法的子菜单按钮类型",
      40025 => "不合法的子菜单按钮名字长度",
      40026 => "不合法的子菜单按钮KEY长度",
      40027 => "不合法的子菜单按钮URL长度",
      40028 => "不合法的自定义菜单使用用户",
      40029 => "不合法的oauth_code",
      40030 => "不合法的refresh_token",
      40031 => "不合法的openid列表",
      40032 => "不合法的openid列表长度",
      40033 => "不合法的请求字符，不能包含xxxx格式的字符",
      40035 => "不合法的参数",
      40038 => "不合法的请求格式",
      40039 => "不合法的URL长度",
      40050 => "不合法的分组id",
      40051 => "分组名字不合法",
      41001 => "缺少access_token参数",
      41002 => "缺少appid参数",
      41003 => "缺少refresh_token参数",
      41004 => "缺少secret参数",
      41005 => "缺少多媒体文件数据",
      41006 => "缺少media_id参数",
      41007 => "缺少子菜单数据",
      41008 => "缺少oauth code",
      41009 => "缺少openid",
      42001 => "access_token超时",
      42002 => "refresh_token超时",
      42003 => "oauth_code超时",
      43001 => "需要GET请求",
      43002 => "需要POST请求",
      43003 => "需要HTTPS请求",
      43004 => "需要接收者关注",
      43005 => "需要好友关系",
      44001 => "多媒体文件为空",
      44002 => "POST的数据包为空",
      44003 => "图文消息内容为空",
      44004 => "文本消息内容为空",
      45001 => "多媒体文件大小超过限制",
      45002 => "消息内容超过限制",
      45003 => "标题字段超过限制",
      45004 => "描述字段超过限制",
      45005 => "链接字段超过限制",
      45006 => "图片链接字段超过限制",
      45007 => "语音播放时间超过限制",
      45008 => "图文消息超过限制",
      45009 => "接口调用超过限制",
      45010 => "创建菜单个数超过限制",
      45015 => "回复时间超过限制",
      45016 => "系统分组，不允许修改",
      45017 => "分组名字过长",
      45018 => "分组数量超过上限",
      46001 => "不存在媒体数据",
      46002 => "不存在的菜单版本",
      46003 => "不存在的菜单数据",
      46004 => "不存在的用户",
      47001 => "解析JSON/XML内容错误",
      48001 => "api功能未授权",
      50001 => "用户未授权该api"
  }
end
