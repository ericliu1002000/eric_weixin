module EricWeixin
  class AccessToken < ActiveRecord::Base
    belongs_to :public_account, :class_name => 'EricWeixin::PublicAccount', foreign_key: :experience_center_id

    self.table_name = "weixin_access_tokens"

    def self.get_valid_access_token_by_app_id options
      pa = ::EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
      ::EricWeixin::AccessToken.get_valid_access_token public_account_id: pa.id
    end


    # 获取有效的Token。
    # 参数为： public_account_id
    #  ::EricWeixin::AccessToken.get_valid_access_token public_account_id: 1
    def self.get_valid_access_token options
      ::EricWeixin::AccessToken.transaction do

        access_token = ::EricWeixin::AccessToken.find_by_public_account_id options[:public_account_id]

        if access_token.blank?
          public_account = ::EricWeixin::PublicAccount.find_by_id options[:public_account_id]
          access_token = ::EricWeixin::AccessToken.new :access_token => get_new_token(options[:public_account_id]),
                                                       :expired_at => Time.now.to_i + 2*60*60,
                                                       :public_account_id => public_account.id
          access_token.save!
        end

        if Time.now.to_i > (access_token.expired_at.to_i - 30)
          access_token.access_token = get_new_token(options[:public_account_id])
          access_token.expired_at = Time.now.to_i + 2*60*60
          access_token.save!
        end
        access_token.reload
        access_token.access_token
      end
    end


    #::EricWeixin::AccessToken.get_new_token '5e3b98ca0000959946657212739fd535'
    def self.get_new_token public_account_id
      account = ::EricWeixin::PublicAccount.find_by_id public_account_id
      BusinessException.raise 'account 不存在' if account.blank?
      url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{'wx51729870d9012531'||account.weixin_app_id}&secret=#{account.weixin_secret_key}"
      response = RestClient.get url

      pp '.........'
      pp response
      JSON.parse(response)["access_token"]
    end
  end
end



