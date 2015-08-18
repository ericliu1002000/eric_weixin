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

end