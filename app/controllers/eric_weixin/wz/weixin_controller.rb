require "pp"
module EricWeixin
  class Wz::WeixinController < ApplicationController
    # 第一次接入时，用于微信服务器验证开者服务器的真实性。
    protect_from_forgery except: :reply
    def index
      render :text => params[:echostr]
    end



    def reply
      request_body = request.body.read
      public_account = PublicAccount.find_by_weixin_app_id params[:app_id]
      BusinessException.raise 'ip不正确' unless Ip.is_ip_exist? public_account_id: public_account.id,
                                ip: get_ip
      "message from wechat: ".to_logger
      request_body.to_logger
      weixin_message = MultiXml.parse(request_body).deep_symbolize_keys[:xml]
      message = ReplyMessageRule.process_rule(weixin_message, public_account)
      render xml: message
    end

    def snsapi_api
      require "base64"
      weixin_public_account = PublicAccount.where(weixin_app_id: params["weixin_app_id"]).first
      response = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{weixin_public_account.weixin_app_id}&secret=#{weixin_public_account.weixin_secret_key}&code=#{params[:code]}&grant_type=authorization_code"
      result_hash = JSON.parse(response.body)
      url = URI(Base64.decode64(params["url"]))
      query_array = URI.decode_www_form url.query||''
      query_array << ["openid", result_hash['openid']]
      query_array << ["state", params["state"]]
      query_str = URI.encode_www_form query_array
      url = [url.to_s.split('?')[0], query_str].join '?'
      redirect_to url
    end

    def snsapi_userinfo
      require "base64"
      weixin_public_account = PublicAccount.where(weixin_app_id: params["weixin_app_id"]).first
      url = URI(Base64.decode64(params["url"]))
      query_array = URI.decode_www_form url.query||''
      query_array << ["state", params["state"]]
      if params[:code].blank?
        #先处理用户不同意的情况下，直接跳转到业务页面，agree参数为no
        query_array << ["agree", 'no']
        query_str = URI.encode_www_form query_array
        url = [url.to_s.split('?')[0], query_str].join '?'
        redirect_to url
        return
      end


      response = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{weixin_public_account.weixin_app_id}&secret=#{weixin_public_account.weixin_secret_key}&code=#{params[:code]}&grant_type=authorization_code"
      result_hash = JSON.parse(response.body)
      query_array << ["openid", result_hash['openid']]
      query_array << ["access_token", result_hash['access_token']]
      query_array << ["expires_in", result_hash['expires_in']]
      query_array << ['refresh_token', result_hash['refresh_token']]
      query_array << ['scope', result_hash['scope']]
      query_array << ['agree', 'yes']

      response = RestClient.get "https://api.weixin.qq.com/sns/userinfo?access_token=#{result_hash['access_token']}&openid=#{result_hash['openid']}&lang=zh_CN"
      user_info_hash = JSON.parse(response.body)
      query_array << ["nickname", user_info_hash['nickname']]
      query_array << ["sex", WeixinUser::SEX[user_info_hash['nickname'].to_i]]
      query_array << ["province", user_info_hash['province']]
      query_array << ["city", user_info_hash['city']]
      query_array << ["country", user_info_hash['country']]
      query_array << ["headimgurl", user_info_hash['headimgurl']]

      query_str = URI.encode_www_form query_array
      url = [url.to_s.split('?')[0], query_str].join '?'
      redirect_to url
    end

    def aa
      @ee = 12
    end

    private
    def get_ip
      ip = request.env["HTTP_X_FORWARDED_FOR"]||"127.0.0.1"
      ip = begin ip.split(',')[0] rescue "127.0.0.1" end
    end

  end
end
