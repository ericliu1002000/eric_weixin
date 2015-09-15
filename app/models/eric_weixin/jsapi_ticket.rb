module EricWeixin
  class JsapiTicket < ActiveRecord::Base

    belongs_to :public_account, :class_name => '::EricWeixin::PublicAccount', foreign_key: :public_account_id

    self.table_name = "weixin_jsapi_tickets"


    # 获取 jsapi ticket 方法一。根据 APPID 查到微信公众号 PublicAccount.id ，然后
    # 调用 ::EricWeixin::JsapiTicket.get_valid_ticket 获取 jsapi ticket 并作为返回值返回.
    # ===参数说明
    # * app_id   #微信公众号的 app_id
    # ===调用示例
    #  ::EricWeixin::JsapiTicket.get_valid_jsapi_ticket_by_app_id app_id: 'wx51729870d9012531'
    def self.get_valid_jsapi_ticket_by_app_id options
      pa = ::EricWeixin::PublicAccount.find_by_weixin_app_id options[:app_id]
      ::EricWeixin::JsapiTicket.get_valid_ticket public_account_id: pa.id
    end

    # 获取 jsapi ticket 方法二。根据微信公众号 PublicAccount.id 获取  jsapi ticket .
    # 若微信公众号未存在  jsapi ticket  或者  jsapi ticket  过期都立即获取新的并返回。
    # ===参数说明
    # * public_account_id   #公众账号 ID
    # ===调用示例
    # ::EricWeixin::JsapiTicket.get_valid_ticket public_account_id: 1
    def self.get_valid_ticket options
      self.transaction do
        ticket = ::EricWeixin::JsapiTicket.find_by_public_account_id options[:public_account_id]
        if ticket.blank?
          public_account = ::EricWeixin::PublicAccount.find_by_id options[:public_account_id]
          ticket = ::EricWeixin::JsapiTicket.new jsapi_ticket: get_new_ticket(public_account.id),
                                                 expired_at: Time.now.to_i + 2*60*60,
                                                 public_account_id: public_account.id
          ticket.save!
        end

        if Time.now.to_i > (ticket.expired_at.to_i - 30)
          ticket.jsapi_ticket = get_new_ticket options[:public_account_id]
          ticket.expired_at = Time.now.to_i + 2*60*60
          ticket.save!
        end
        ticket.reload
        ticket.jsapi_ticket
      end
    end

    # 根据微信公众号从微信服务器获取最新的 AccessToken.
    # ===参数说明
    # * public_account_id   #公众账号 ID
    # ===调用示例
    # ::EricWeixin::AccessToken.get_new_token '5e3b98ca0000959946657212739fd535'
    # https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=12&secret=23
    def self.get_new_ticket public_account_id
      account = ::EricWeixin::PublicAccount.find_by_id public_account_id
      BusinessException.raise 'account 不存在' if account.blank?
      # url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{account.weixin_app_id}&secret=#{account.weixin_secret_key}"
      access_token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: account.id
      url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{access_token}&type=jsapi"
      response = RestClient.get url
      pp response
      JSON.parse(response)["ticket"]
    end
  end
end



