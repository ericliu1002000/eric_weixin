# 数据统计接口模块
module EricWeixin::AnalyzeData

  # -------------------用户分析数据接口------------------------------------

  def self.get_user_summary options
    get_data_json "https://api.weixin.qq.com/datacube/getusersummary?access_token=", options
  end

  def self.get_user_cumulate options
    get_data_json "https://api.weixin.qq.com/datacube/getusercumulate?access_token=", options
  end

  # -------------------图文分析数据接口------------------------------------

  # 获取图文群发每日数据（getarticlesummary）
  def self.get_article_summary options
    get_data_json "https://api.weixin.qq.com/datacube/getarticlesummary?access_token=", options
  end

  # 获取图文群发总数据（getarticletotal）
  def self.get_article_total options
    get_data_json "https://api.weixin.qq.com/datacube/getarticletotal?access_token=", options
  end

  # 获取图文统计数据（getuserread）
  def self.get_user_read options
    get_data_json "https://api.weixin.qq.com/datacube/getuserread?access_token=", options
  end

  # 获取图文统计分时数据（getuserreadhour）
  def self.get_user_read_hour options
    get_data_json "https://api.weixin.qq.com/datacube/getuserreadhour?access_token=", options
  end

  # 获取图文分享转发数据（getusershare）
  def self.get_user_share options
    get_data_json "https://api.weixin.qq.com/datacube/getusershare?access_token=", options
  end

  # 获取图文分享转发分时数据（getusersharehour）
  def self.get_user_share_hour options
    get_data_json "https://api.weixin.qq.com/datacube/getusersharehour?access_token=", options
  end

  # -------------------消息分析数据接口------------------------------------

  # 获取消息发送概况数据（getupstreammsg）
  def self.get_upstream_msg options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsg?access_token=", options
  end

  # 获取消息分送分时数据（getupstreammsghour）
  def self.get_upstream_msg_hour options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsghour?access_token=", options
  end

  # 获取消息发送周数据（getupstreammsgweek）
  def self.get_upstream_msg_week options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsgweek?access_token=", options
  end

  # 获取消息发送月数据（getupstreammsgmonth）
  def self.get_upstream_msg_month options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsgmonth?access_token=", options
  end

  # 获取消息发送分布数据（getupstreammsgdist）
  def self.get_upstream_msg_dist options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsgdist?access_token=", options
  end

  # 获取消息发送分布周数据（getupstreammsgdistweek）
  def self.get_upstream_msg_dist_week options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsgdistweek?access_token=", options
  end

  # 获取消息发送分布月数据（getupstreammsgdistmonth）
  def self.get_upstream_msg_dist_month options
    get_data_json "https://api.weixin.qq.com/datacube/getupstreammsgdistmonth?access_token=", options
  end




  def self.get_data_json url, options
    token = get_access_token options
    url = url + token
    post_data = {
        :begin_date => options[:begin_date],
        :end_date => options[:end_date]
    }
    response = RestClient.post url, post_data.to_json
    response = JSON.parse response.body
    response
  end

  def self.get_access_token options
    pa = if options[:weixin_public_account_id].blank?
      if options[:app_id].blank?
        pa = ::EricWeixin::PublicAccount.find_by_weixin_number options[:weixin_number]
        options[:app_id] = pa.weixin_app_id
        pa
      else
        ::EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
      end
    else
      ::EricWeixin::PublicAccount.find(options[:weixin_public_account_id])
    end
    BusinessException.raise '公众账号未查询到' if pa.blank?
    ::EricWeixin::AccessToken.get_valid_access_token_by_app_id app_id: pa.weixin_app_id
  end
end
