module EricWeixin
  class AccessToken < ActiveRecord::Base

    self.table_name = "weixin_access_tokens"

    def self.get_valid_access_token_by_app_id options
      secret_key = ::EricWeixin::PublicAccount.get_secret options[:app_id]
      ::EricWeixin::AccessToken.get_valid_access_token weixin_secret_key: secret_key
    end


    # 获取有效的Token
    # 参数为： weixin_secret_key
    #  ::EricWeixin::AccessToken.get_valid_access_token weixin_secret_key: 'bba7ba32bf3e1a60edd8bd8903ce33e5'
    def self.get_valid_access_token options
      ::EricWeixin::AccessToken.transaction do
        access_token = ::EricWeixin::AccessToken.where(weixin_secret_key: options[:weixin_secret_key]).first
        if access_token.blank?
          public_account = ::EricWeixin::PublicAccount.find_by_weixin_secret_key(options[:weixin_secret_key]).first
          access_token = ::EricWeixin::AccessToken.new :weixin_secret_key => options[:weixin_secret_key],
                                                   :access_token => get_new_token(options[:weixin_secret_key]),
                                                   :expired_at => Time.now.to_i + 2*60*60,
                                                   :public_account_id => public_account.id
          access_token.save!
        end

        if Time.now.to_i > (access_token.expired_at.to_i - 30)
          access_token.access_token = get_new_token(options[:weixin_secret_key])
          access_token.expired_at = Time.now.to_i + 2*60*60
          access_token.save!
        end
        access_token.reload
        access_token.access_token
      end
    end


    private
    #::EricWeixin::AccessToken.get_new_token 'bba7ba32bf3e1a60edd8bd8903ce33e5'
    def self.get_new_token secret_key
      account = ::EricWeixin::PublicAccount.where(:weixin_secret_key => secret_key).first
      BusinessException.raise 'account 不存在' if account.blank?
      response = RestClient.get "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{account.weixin_app_id}&secret=#{account.weixin_secret_key}"
      JSON.parse(response)["access_token"]
    end
  end
end



