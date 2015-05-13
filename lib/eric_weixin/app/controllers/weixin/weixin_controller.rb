require "pp"
module EricWeixin
  class WeixinController < ActionController::Base
    # 第一次接入时，用于微信服务器验证开者服务器的真实性。
    def index
      render  :text => params[:echostr]
    end

    def reply
      request_body = request.body.read
      weixin_secret_key = ::EricWeixin::PublicAccount.get_secret params[:app_id]

      "message from wechat: ".to_logger
      request_body.to_logger
      weixin_message = MultiXml.parse(request_body).deep_symbolize_keys[:xml]

      message = ::EricWeixin::ReplyMessageRule.process_rule(weixin_message, weixin_secret_key)
      render xml: message
    end

    def snsapi_api
      require "base64"
      weixin_public_account = EricWeixin::PublicAccount.where(name: params["public_account_name"]).first
      response = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{weixin_public_account.weixin_app_id}&secret=#{weixin_public_account.weixin_secret_key}&code=#{params[:code]}&grant_type=authorization_code"
      result_hash = JSON.parse(response.body)
      url = "#{Base64.decode64(params["url"])}&openid=#{result_hash['openid']}"
      redirect_to url
    end

    def aa
      @ee = 12
    end



  end
end
