class EricWeixin::RedpackOrder < ActiveRecord::Base
  self.table_name = 'weixin_redpack_orders'
  belongs_to :public_account, foreign_key: "weixin_public_account_id"
  has_many :redpacks, foreign_key: 'weixin_redpack_order_id'

  SENDTYPE = {
      "API" => "通过API接口发放",
      "UPLOAD" => "通过上传文件方式发放",
      "ACTIVITY" => "通过活动方式发放"
  }
  HBTYPE = {
      "GROUP" => "裂变红包",
      "NORMAL" => "普通红包"
  }

  validates_presence_of :mch_billno, message: '商户订单号必填。'

  # ================必填参数===================
  # re_openid
  # total_amount
  # wishing
  # client_ip
  # act_name
  # remark
  # send_name
  # ================选填参数===================
  # wxappid
  # mch_id
  # mch_key
  # total_num
  def self.create_redpack_order options
    self.transaction do
      weixin_user = ::Weixin::WeixinUser.find_by_openid(options[:re_openid])
      public_account = weixin_user.weixin_public_account||EricWeixin::PublicAccount.find_by_weixin_app_id(params[:wxappid])
      BusinessException.raise '查找不到对应的公众号。' if public_account.blank?
      options[:wxappid] = options[:wxappid]||public_account.weixin_app_id
      options[:mch_id] = options[:mch_id]||public_account.mch_id
      options[:total_num] ||= 1
      options[:mch_key] = options[:mch_key]||public_account.mch_key
      result = EricWeixin::Pay.sendredpack options
      pp "*********************** 发红包结果 **************************"
      pp result
      BusinessException.raise result['return_msg'] if result['return_code'] == 'FAIL'
      redpack_order = self.new
      redpack_order.mch_billno = result['mch_billno']
      redpack_order.weixin_public_account_id = public_account.id
      redpack_order.save!
      redpack_order
    end
  end

  def get_info
    EricWeixin::RedpackOrder.transaction do
      options = {}
      options[:mch_billno] = self.mch_billno
      options[:mch_id] = self.public_account.mch_id
      options[:appid] = self.public_account.weixin_app_id
      options[:mch_key] = self.public_account.mch_key
      result = EricWeixin::Pay.gethbinfo options
      pp "************************ 查询红包结果 *****************************"
      pp result
      BusinessException.raise result['return_msg'] if result['return_code'] = 'FAIL'
      self.detail_id = result['detail_id']
      self.send_type = result['send_type']
      self.hb_type = result['hb_type']
      self.total_num = result['Total_num']
      self.total_amount = result['Total_amount']
      self.reason = result['reason']
      self.send_time = result['Send_time']
      self.refund_time = result['Refund_time']
      self.refund_amount = result['Refund_amount']
      self.wishing = result['wishing']
      self.remark = result['Remark']
      self.act_name = result['Act_name']
      self.save!
      result['hblist'].each do |hbinfo|
        options[:status] = hbinfo['status']
        options[:openid] = hbinfo['openid']
        options[:amount] = hbinfo['amount']
        options[:rcv_time] = hbinfo['rcv_time']
        redpack = EricWeixin::Redpack.create_redpack options
        redpack.redpack_order = self
        redpack.save!
      end
    end
  end

end