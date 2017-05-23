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
      return '不能小于1元' if options[:total_amount].to_i < 100
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
      return result['err_code'] if result['return_code'] == 'FAIL'
      redpack_order = self.new
      redpack_order.mch_billno = result['mch_billno']
      redpack_order.weixin_public_account_id = public_account.id
      redpack_order.save!
      redpack_order
    end
  end

  # 定时使用 redpack_order 实例变量来完善补充红包信息。
  def get_info
    # return if self.redpacks.blank?
    EricWeixin::RedpackOrder.transaction do
      options = {}
      options[:mch_billno] = self.mch_billno
      options[:mch_id] = self.public_account.mch_id
      options[:appid] = self.public_account.weixin_app_id
      options[:mch_key] = self.public_account.mch_key
      result = EricWeixin::Pay.gethbinfo options
      pp "************************ 查询红包结果 *****************************"
      pp result
      return result['err_code'] if result['return_code'] == 'FAIL'
      self.detail_id = result['detail_id']
      self.send_type = result['send_type']
      self.hb_type = result['hb_type']
      self.total_num = result['total_num']
      self.total_amount = result['total_amount']
      self.reason = result['reason']
      self.send_time = result['send_time']
      self.refund_time = result['refund_time']
      self.refund_amount = result['refund_amount']
      self.wishing = result['wishing']
      self.remark = result['emark']
      self.act_name = result['act_name']
      self.save!
      hbinfo = (result['hblist']['hbinfo'] rescue '')

      unless hbinfo.blank?
        options[:status] = hbinfo['status']
        options[:openid] = hbinfo['openid']
        options[:amount] = hbinfo['amount']
        options[:rcv_time] = hbinfo['rcv_time']
        options[:weixin_redpack_order_id] = self.id
        EricWeixin::Redpack.create_redpack options
      end


    end
  end

  # 指定公众号，从微信服务器更新红包信息
  # EricWeixin::RedpackOrder.update_info_from_wx 1
  def self.update_info_from_wx public_account_id
    self.where("detail_id is null and weixin_public_account_id = ? ", public_account_id).each do |r_o|
      r_o.get_info
    end
    return
  end

end