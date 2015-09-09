class EricWeixin::Wz::PaysController < ApplicationController

  def prepay
    @prepay_id = ::EricWeixin::Pay.generate_prepay_id params
  end

  def pay_ok
    render text: '您支付成功，谢谢。'
  end

  def pay_fail
    render text: '您支付失败，请返回重新尝试，谢谢。'
  end

  # wxappid
  # re_openid
  # total_amount
  # wishing
  # client_ip
  # act_name
  # remark
  # def sendredpack
  #   pp "******************* params *********************"
  #   pp params
  #   weixin_user = ::Weixin::WeixinUser.find_by_openid(params[:openid])
  #   public_account = weixin_user.weixin_public_account
  #   options = {}
  #   options[:wxappid] = public_account.weixin_app_id
  #   options[:re_openid] = params[:openid]
  #   options[:total_amount] = params[:total_fee]
  #   options[:wishing] = "恭喜发财"
  #   options[:client_ip] = get_ip
  #   options[:act_name] = "送福利"
  #   options[:remark] = "第一次送"
  #   EricWeixin::Pay.sendredpack options
  #   render text: 'ok'
  # end

end