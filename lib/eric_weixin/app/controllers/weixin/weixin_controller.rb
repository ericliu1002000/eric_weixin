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

    def aa
      @ee = 12
    end

  end
end
