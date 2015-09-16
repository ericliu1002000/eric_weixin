class EricWeixin::WeixinUser < ActiveRecord::Base
  SEX = {1=>'男' , 2=>'女', 0=>'未知'}
  self.table_name = 'weixin_users'
  belongs_to :member_info
  belongs_to :weixin_public_account, :class_name => '::EricWeixin::PublicAccount', :foreign_key => 'weixin_public_account_id'
  validates_uniqueness_of :openid, scope: :weixin_public_account_id
  validates_presence_of :openid, :weixin_public_account_id

  # 在 WeixinUser 模型中查询符合给定哈希的微信用户.
  # 支持该模型的所有参数作为查询条件
  # ===参数说明
  # * nickname  ::微信用户的昵称
  # * openid    ::用户的openid,微信服务器传送过来。
  # ===调用方法
  #  ::EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
  #  ::EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
  def self.search_weixin_user user
    @target_user = ::EricWeixin::WeixinUser.all
    @target_user = @target_user.where("id = ?", user[:id]) unless user[:id].blank?
    @target_user = @target_user.where("openid = ?", user[:openid]) unless user[:openid].blank?
    @target_user = @target_user.where("created_at > ? AND created_at < ?", user[:created_at_start], user[:created_at_end]) unless user[:created_at_start].blank? || user[:created_at_end].blank?
    @target_user = @target_user.where("updated_at > ? AND updated_at < ?", user[:updated_at_start], user[:updated_at_end]) unless user[:updated_at_start].blank? || user[:updated_at_end].blank?
    @target_user = @target_user.where("subscribe = ?", user[:subscribe]) unless user[:subscribe].blank?
    @target_user = @target_user.where("nickname = ?", CGI::escape(user[:nickname])) unless user[:nickname].blank?
    @target_user = @target_user.where("sex = ?", user[:sex]) unless user[:sex].blank?
    @target_user = @target_user.where("language = ?", user[:language]) unless user[:language].blank?
    @target_user = @target_user.where("city = ?", user[:city]) unless user[:city].blank?
    @target_user = @target_user.where("province = ?", user[:province]) unless user[:province].blank?
    @target_user = @target_user.where("country = ?", user[:country]) unless user[:country].blank?
    @target_user = @target_user.where("subscribe_time > ? AND subscribe_time < ?", user[:subscribe_time_start], user[:subscribe_time_end]) unless user[:subscribe_time_start].blank? || user[:subscribe_time_end].blank?
    @target_user = @target_user.where("remark = ?", user[:remark]) unless user[:remark].blank?
    @target_user = @target_user.where("member_info_id = ?", user[:member_info_id]) unless user[:member_info_id].blank?
    @target_user = @target_user.where("weixin_public_account_id = ?", user[:weixin_public_account_id]) unless user[:weixin_public_account_id].blank?
    @target_user = @target_user.where("last_register_channel = ?", user[:last_register_channel]) unless user[:last_register_channel].blank?
    @target_user = @target_user.where("first_register_channel = ?", user[:first_register_channel]) unless user[:first_register_channel].blank?
    @target_user
  end

  def nickname
    CGI::unescape(self.attributes["nickname"]) rescue '无法正常显示'
  end

  ##
  # 关注状态，关注返回true， 否则返回false.
  def follow_status
    self.subscribe.to_i == 1
  end

  #设置备注名
  def set_remark name
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.weixin_public_account_id
    url = "https://api.weixin.qq.com/cgi-bin/user/info/updateremark?access_token=#{token}"
    response = RestClient.post url, {:openid => self.openid, :remark => name}.to_json
    response.to_debug
    response = JSON.parse response.body
    if response["errcode"].to_i == 0
      ::EricWeixin::WeixinUser.create_weixin_user self.weixin_public_account_id, self.openid

    else
      BusinessException.raise "设置备注名报错，错误代码为#{response["errcode"]}"
    end
  end

  class << self

    # ===业务说明：创建、更新微信用户.
    # * 微信用户在关注、取消关注时更新用户信息。
    # * 当用户关注微信时，创建用户。
    # * 当用户取消关注时，把用户标记为取消关注
    # ===参数说明
    # * public_account_id::公众账号的数据库存储id
    # * openid::用户的openid,微信服务器传送过来。
    # ===调用方法
    #  ::EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
    #  ::EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
    # ====返回
    # 正常情况下返回当前微信用户 <tt>::EricWeixin::WeixinUser</tt>，抛出异常时错误查看异常信息。
    def create_weixin_user(public_account_id, openid, channel=nil)
      is_new = false
      public_account = ::EricWeixin::PublicAccount.find_by_id(public_account_id)
      ::EricWeixin::ReplyMessageRule.transaction do
        is_new = false
        weixin_user = ::EricWeixin::WeixinUser.where(openid: openid, weixin_public_account_id: public_account.id).first
        if weixin_user.blank?
          is_new = true
          weixin_user = ::EricWeixin::WeixinUser.new openid: openid,
                                       weixin_public_account_id: public_account.id
          weixin_user.save!
          is_new = true
        end
        wx_user_data = public_account.get_user_data_from_weixin_api openid
        weixin_user.update_attributes(wx_user_data.select{|k,v| ["subscribe", "openid", "nickname", "sex", "language", "city", "province", "country", "headimgurl", "subscribe_time", "remark"].include? k })
        if not channel.blank?
          weixin_user.first_register_channel = channel if weixin_user.first_register_channel.blank?
          weixin_user.last_register_channel = channel
          weixin_user.save!
        end
        return weixin_user, is_new
      end
    end

    # ===获取用户详情.
    # 根据公众账号id和openid获取公众账号详细信息，最后返回json。
    # ===输入参数说明
    # * public_account_id 公众账号的id，你懂得，就是public_accounts表中的id。
    # * openid WX分配给用户的id
    # ===返回
    # WX返回的用户详细信息，以json格式返回。#
    def get_user_data_from_weixin_api public_account_id, openid
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: public_account_id
      response = RestClient.get "https://api.weixin.qq.com/cgi-bin/user/info?access_token=#{token}&openid=#{openid}&lang=zh_CN"
      response = JSON.parse response.body
      response["nickname"] = CGI::escape(response["nickname"]) if not response["nickname"].blank?
      response
    end

    def export_users_to_csv(public_account_id)
      require 'csv'
      weixin_users = ::EricWeixin::WeixinUser.where(weixin_public_account_id: public_account_id)
      CSV.generate do |csv|
        csv << ["订阅状态", "openid", "昵称", "性别", "语言", "城市", "省份", "国家", "订阅时间"]
        weixin_users.each do |weixin_user|
          user_fields = []
          user_fields << (weixin_user.follow_status ? '订阅': '取消订阅')
          user_fields << weixin_user.openid
          user_fields << weixin_user.nickname
          user_fields << case weixin_user.sex when 1 then '男' when 2 then '女' else '未知' end
          user_fields << case weixin_user.language when 'zh_CN' then '简体中文' when 'zh_TW' then '繁体中文' when 'en' then '英文' else '其它' end
          user_fields << weixin_user.city
          user_fields << weixin_user.province
          user_fields << weixin_user.country
          user_fields << Time.at(weixin_user.subscribe_time.to_i).chinese_format
          csv << user_fields
        end
        csv
      end
    end


    #绑定会员
    def connect_member(options)
      openid = options[:openid]
      user_name = options[:username]
      password = options[:password]

      ::EricWeixin::WeixinUser.transaction do
        member_info = MemberInfo.where(user_name: user_name, password: password).first
        BusinessException.raise '该会员不存在' if member_info.blank?

        weixin_user = ::EricWeixin::WeixinUser.find_by_openid(openid)
        BusinessException.raise '该微信用户不存在' if weixin_user.blank?

        weixin_user.member_info = member_info
        weixin_user.save!
        member_info
      end
    end

    def custom_query options
      users = self.all
      users = users.where(subscribe: options[:subscribe]) unless options[:subscribe].blank?
      users = users.where("nickname like ?", "%#{CGI::escape(options[:nickname])}%") unless options[:nickname].blank?
      users = users.where(sex: options[:sex]) unless options[:sex].blank?
      users = users.where(city: options[:city]) unless options[:city].blank?
      users = users.where(province: options[:province]) unless options[:province].blank?
      users = users.where(weixin_public_account_id: options[:weixin_public_account_id]) unless options[:weixin_public_account_id].blank?
      users = users.where("subscribe_time >= ?", options[:start_date].to_date.to_time.to_i) unless options[:start_date].blank?
      users = users.where("subscribe_time <= ?", (options[:end_date].to_date+1.day).to_time.to_i) unless options[:end_date].blank?
      users = users.where("last_register_channel = ?", options[:last_register_channel]) unless options[:last_register_channel].blank?
      users = users.where("first_register_channel = ?", options[:first_register_channel]) unless options[:first_register_channel].blank?
      users
    end
  end
end
