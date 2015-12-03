class EricWeixin::Xiaodian::Order < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_orders'

  # 接收订单
  DELIVERY_COMPANY = {
      "Fsearch_code" => "邮政EMS",
      "002shentong" => "申通快递",
      "066zhongtong" => "中通速递",
      "056yuantong" => "圆通速递",
      "042tiantian" => "天天快递",
      "003shunfeng" => "顺丰速运",
      "059Yunda" => "韵达快运",
      "064zhaijisong" => "宅急送",
      "020huitong" => "汇通快运",
      "zj001yixun" => "易迅快递"
  }


  # 创建订单
  # 参数：
  #   OrderId  订单ID
  #   FromUserName  用户userid
  #   ToUserName 公众账号微信号
  #   ProductId
  #   CreateTime
  #   SkuInfo
  #   OrderStatus
  #
  def self.create_order options
    order = EricWeixin::Xiaodian::Order.where(order_id: options[:OrderId]).first
    unless order.blank?
      order.get_info
      return order
    end

    openid = options[:FromUserName]
    user = EricWeixin::WeixinUser.where(openid: openid).first

    to_user_name = options[:ToUserName]
    account = EricWeixin::PublicAccount.where(weixin_number: to_user_name).first

    product = EricWeixin::Xiaodian::Product.where(product_id: options[:ProductId]).first
    if product.blank?
      EricWeixin::Xiaodian::Product.get_all_products account.name
      product = EricWeixin::Xiaodian::Product.where(product_id: options[:ProductId]).first
    end


    if user.blank?
      account.rebuild_users_simple
      user = EricWeixin::WeixinUser.where(openid: openid).first
    end

    user_id = user.blank? ? nil : user.id

    order = EricWeixin::Xiaodian::Order.new order_id: options[:OrderId],
                                            weixin_user_id: user_id,
                                            order_create_time: options[:CreateTime],
                                            order_status: options[:OrderStatus],
                                            weixin_product_id: product.id,
                                            sku_info: options[:SkuInfo],
                                            weixin_public_account_id: account.id,
                                            openid: openid
    order.save!

    order.get_info

    order
  end


  # 根据订单ID获取订单详情
  def get_info
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.weixin_public_account_id
    param = {order_id: self.order_id}
    response = RestClient.post "https://api.weixin.qq.com/merchant/order/getbyid?access_token=#{token}", param.to_json
    response = JSON.parse response.body
    if response["errcode"] == 0
      order_params = response["order"]
      ["receiver_zip", "product_id", "buyer_openid"].each do |a|
        order_params.delete a
      end



      # 获取订单详情前，weixin_product_id、sku_info、weixin_user_id应该已经有了值
      # weixin_product = EricWeixin::Xiaodian::Product.where( product_id: order_params["product_id"], weixin_public_account_id: self.weixin_public_account_id ).first
      # order_params.merge!("weixin_product_id"=>weixin_product.id) unless weixin_product.blank?
      # weixin_user = EricWeixin::WeixinUser.where(openid: order_params["buyer_openid"], weixin_public_account_id: self.weixin_public_account_id).first
      # order_params.merge!("weixin_user_id"=>weixin_user.id) unless weixin_user.blank?

      self.update_attributes order_params
    else
      pp response
      return
    end
  end

  #	根据订单状态/创建时间获取订单详情,并更新自身数据库
  # EricWeixin::Xiaodian::Order.get_order_list_and_update nil, nil ,nil ,'rszx'
  def self.get_order_list_and_update begin_time, end_time, status, public_account_name
    account = EricWeixin::PublicAccount.get_public_account_by_name public_account_name
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: account.id

    param = {:a => 1}
    if !begin_time.blank? and !end_time.blank?
      param = {begintime: begin_time.to_i, endtime: end_time.to_i}
    end

    param.merge!(status: status) unless status.blank?

    response = RestClient.post "https://api.weixin.qq.com/merchant/order/getbyfilter?access_token=#{token}", param.to_json
    response = JSON.parse response.body
    if response["errcode"] == 0
      order_list = response["order_list"]
      order_list.each do |order|
        EricWeixin::Xiaodian::Order.create_order OrderId: order["order_id"],
                                                 FromUserName: order["buyer_openid"],
                                                 ToUserName: account.weixin_number,
                                                 ProductId: order["product_id"],
                                                 CreateTime: order["order_create_time"],
                                                 SkuInfo: order["product_sku"],
                                                 OrderStatus: order["order_status"]
      end
    else
      pp response
      return
    end
  end

  # 设置订单发货信息
  # 参数如下：
  # {
  #    "delivery_company": "059Yunda",
  #    "delivery_track_no": "1900659372473",
  #    "need_delivery": 1,
  #    "is_others": 0
  # }
  #
  # 参数解释如下：
  #
  # delivery_company
  # 物流公司ID(参考《物流公司ID》；
  # 当need_delivery为0时，可不填本字段；
  # 当need_delivery为1时，该字段不能为空；
  # 当need_delivery为1且is_others为1时，本字段填写其它物流公司名称)
  #
  # delivery_track_no
  # 运单ID(
  #     当need_delivery为0时，可不填本字段；
  # 当need_delivery为1时，该字段不能为空；
  # )
  #
  # need_delivery
  # 商品是否需要物流(0-不需要，1-需要，无该字段默认为需要物流)
  #
  # is_others
  # 是否为6.4.5表之外的其它物流公司(0-否，1-是，无该字段默认为不是其它物流公司)

  def set_delivery options
    pp options
    if options["need_delivery"].to_s == "0"
      options = {need_delivery: 0}
    else
      BusinessException.raise 'need_delivery不为0时，delivery_track_no字段必填' if options["delivery_track_no"].blank?
      BusinessException.raise 'need_delivery不为0时，delivery_company字段不可以为空' if options["delivery_company"].blank?
      if options["is_others"].to_s != "1"
        BusinessException.raise 'need_delivery不为0且is_others不为1时，delivery_company字段必须是规定的快递公司ID' unless DELIVERY_COMPANY.include? options["delivery_company"]
      end
    end
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: self.weixin_public_account_id
    options.merge!("order_id" => self.order_id)
    response = RestClient.post "https://api.weixin.qq.com/merchant/order/setdelivery?access_token=#{token}", options.to_json
    response = JSON.parse response.body
    if response["errcode"] == 0
      true
      if options["need_delivery"].to_s == "0"
        self.update_attributes delivery_id: "", delivery_company: ""
      else
        self.update_attributes delivery_id: options["delivery_track_no"], delivery_company: options["delivery_company"]
      end
    else
      false
    end
  end

end