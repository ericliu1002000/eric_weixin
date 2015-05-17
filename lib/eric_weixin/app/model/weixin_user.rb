class EricWeixin::WeixinUser < ActiveRecord::Base
  SEX = {1=>'男' , 2=>'女', 0=>'未知'}
  belongs_to :member_info
  belongs_to :weixin_public_account, :class_name => '::EricWeixin::PublicAccount', :foreign_key => 'weixin_public_account_id'
  validates_uniqueness_of :openid, scope: :weixin_secret_key
  validates_presence_of :openid, :weixin_secret_key, :weixin_public_account


  def nickname
    CGI::unescape(self.attributes["nickname"])
  end

  ##
  # 关注状态，关注返回true， 否则返回false.
  def follow_status
    self.subscribe.to_i == 1
  end

  class << self

    ##
    # ===业务说明：创建、更新微信用户
    # * 微信用户在关注、取消关注时更新用户信息。
    # * 当用户关注微信时，创建用户。
    # * 当用户取消关注时，把用户标记为取消关注
    # ===参数说明
    # * secret_key::公众账号的secret_key,其值取决于公众账号的设置。
    # * openid::用户的openid,微信服务器传送过来。
    # ===调用方法
    #  EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
    #  EricWeixin::WeixinUser.create_weixin_user 'adsfkj', 'sdfdf'
    # ====返回
    # 正常情况下返回当前微信用户 <tt>::EricWeixin::WeixinUser</tt>，抛出异常时错误查看异常信息。
    def create_weixin_user(secret_key, openid)
      public_account = ::EricWeixin::PublicAccount.find_by_weixin_secret_key(secret_key)
      ::EricWeixin::ReplyMessageRule.transaction do
        weixin_user = ::EricWeixin::WeixinUser.where(openid: openid, weixin_secret_key: secret_key).first
        if weixin_user.blank?
          weixin_user = ::EricWeixin::WeixinUser.new openid: openid,
                                       weixin_secret_key: secret_key,
                                       weixin_public_account_id: public_account.id
          weixin_user.save!
        end
        wx_user_data = public_account.get_user_data_from_weixin_api openid
        weixin_user.update_attributes(wx_user_data.select{|k,v| ["subscribe", "openid", "nickname", "sex", "language", "city", "province", "country", "headimgurl", "subscribe_time", "remark"].include? k })
        weixin_user
      end
    end


    def export_users_to_csv(weixin_secret_key)
      require 'csv'
      weixin_users = ::EricWeixin::WeixinUser.where(weixin_secret_key: weixin_secret_key)
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
  end
end
