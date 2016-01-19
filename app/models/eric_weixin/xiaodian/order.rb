class EricWeixin::Xiaodian::Order < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_orders'
  belongs_to :weixin_user, class_name: "::EricWeixin::WeixinUser"
  belongs_to :product, class_name: "::EricWeixin::Xiaodian::Product", foreign_key: 'weixin_product_id'
  belongs_to :weixin_public_account, class_name: "::EricWeixin::PublicAccount", foreign_key: 'weixin_public_account_id'
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

  def product_info
    return '' if self.sku_info.blank?
    info = ""
    list = self.sku_info.split(";")
    list.each do |sku|
      str = sku.split(":")[1]
      if str.match /^\$/
        info += str[1,str.size-1]
        info += "、"
      end
      if str.match /^\d/
        wx_value = ::EricWeixin::Xiaodian::SkuValue.find_by_wx_value_id(str)
        unless wx_value.blank?
          info += wx_value.name
          info += "、"
        end
      end
    end
    info
  end

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
      order.delay(:priority => -10).get_info
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

    order.delay(:priority => -10).get_info

    order
  end


  def buyer_nick
    CGI::unescape(self.attributes["buyer_nick"]) rescue '无法正常显示'
  end

  # 更新指定时间区间的订单信息
  def self.update_order_infos start_date, end_date
    self.where("order_create_time between ? and ? ", start_date.to_i, end_date.to_i).each do |order|
      order.get_info
    end
    true
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
      order_params["buyer_nick"] = CGI::escape(order_params["buyer_nick"]) if not order_params["buyer_nick"].blank?
      # 获取订单详情前，weixin_product_id、sku_info、weixin_user_id应该已经有了值
      # weixin_product = EricWeixin::Xiaodian::Product.where( product_id: order_params["product_id"], weixin_public_account_id: self.weixin_public_account_id ).first
      # order_params.merge!("weixin_product_id"=>weixin_product.id) unless weixin_product.blank?
      # weixin_user = EricWeixin::WeixinUser.where(openid: order_params["buyer_openid"], weixin_public_account_id: self.weixin_public_account_id).first
      # order_params.merge!("weixin_user_id"=>weixin_user.id) unless weixin_user.blank?

      order_params = order_params.select{|k,v|["order_status",
                                               "order_total_price",
                                               "order_create_time",
                                               "order_express_price",
                                               "buyer_openid",
                                               "buyer_nick",
                                               "receiver_name",
                                               "receiver_province",
                                               "receiver_city",
                                               "receiver_address",
                                               "receiver_mobile",
                                               "receiver_phone",
                                               "product_name",
                                               "product_price",
                                               "product_sku",
                                               "product_count",
                                               "product_img",
                                               "delivery_id",
                                               "delivery_company",
                                               "trans_id",
                                               "receiver_zone"].include?(k) && !v.blank? }
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

  def self.get_excel_of_orders options
    orders = self.all
    orders = orders.where("order_create_time >= ?", options[:start_date].to_time.change(hour:0,min:0,sec:0).to_i) unless options[:start_date].blank?
    orders = orders.where("order_create_time <= ?", options[:end_date].to_time.change(hour:23,min:59,sec:59).to_i) unless options[:end_date].blank?
    orders = orders.order(order_create_time: :desc)

    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: '订单表'
    sheet1.row(0)[0] = "id"
    sheet1.row(0)[1] = "买家昵称"
    sheet1.row(0)[2] = "订单ID"
    sheet1.row(0)[3] = "产品名称"
    sheet1.row(0)[4] = "sku"
    sheet1.row(0)[5] = "订单状态"
    sheet1.row(0)[6] = "总金额"
    sheet1.row(0)[7] = "订单生成时间"
    sheet1.row(0)[8] = "快递费"
    sheet1.row(0)[9] = "昵称"
    sheet1.row(0)[10] = "收货人"
    sheet1.row(0)[11] = "省"
    sheet1.row(0)[12] = "城市"
    sheet1.row(0)[13] = "区"
    sheet1.row(0)[14] = "地址"
    sheet1.row(0)[15] = "移动电话"
    sheet1.row(0)[16] = "固定电话"
    sheet1.row(0)[17] = "产品名"
    sheet1.row(0)[18] = "单价"
    sheet1.row(0)[19] = "产品sku"
    sheet1.row(0)[20] = "数量"
    sheet1.row(0)[21] = "产品图片url"
    sheet1.row(0)[22] = "运单ID"
    sheet1.row(0)[23] = "快递公司"
    sheet1.row(0)[24] = "交易ID"
    sheet1.row(0)[25] = "openid"
    sheet1.row(0)[26] = "公众号名称"
    current_row = 1
    orders.each do |order|
      sheet1.row(current_row)[0] = order.id
      sheet1.row(current_row)[1] = order.weixin_user.nickname rescue ''
      sheet1.row(current_row)[2] = order.order_id
      sheet1.row(current_row)[3] = order.product.name rescue ''
      sheet1.row(current_row)[4] = order.product_info rescue ''
      sheet1.row(current_row)[5] = order.order_status
      sheet1.row(current_row)[6] = (order.order_total_price/100.0).round(2) rescue ''
      sheet1.row(current_row)[7] = Time.at(order.order_create_time).strftime("%Y-%m-%d %H:%M:%S") rescue ''
      sheet1.row(current_row)[8] = (order.order_express_price/100.0).round(2) rescue ''
      sheet1.row(current_row)[9] = order.buyer_nick rescue ''
      sheet1.row(current_row)[10] = order.receiver_name
      sheet1.row(current_row)[11] = order.receiver_province
      sheet1.row(current_row)[12] = order.receiver_city
      sheet1.row(current_row)[13] = order.receiver_zone
      sheet1.row(current_row)[14] = order.receiver_address
      sheet1.row(current_row)[15] = order.receiver_mobile
      sheet1.row(current_row)[16] = order.receiver_phone
      sheet1.row(current_row)[17] = order.product_name
      sheet1.row(current_row)[18] = (order.product_price/100.0).round(2) rescue ''
      sheet1.row(current_row)[19] = order.product_sku
      sheet1.row(current_row)[20] = order.product_count
      sheet1.row(current_row)[21] = order.product_img
      sheet1.row(current_row)[22] = order.delivery_id
      sheet1.row(current_row)[23] = self::DELIVERY_COMPANY[order.delivery_company]||order.delivery_company rescue ''
      sheet1.row(current_row)[24] = order.trans_id
      sheet1.row(current_row)[25] = order.openid
      sheet1.row(current_row)[26] = order.weixin_public_account.name
      current_row += 1
    end
    dir = Rails.root.join('public', 'downloads')
    Dir.mkdir dir unless Dir.exist? dir
    file_path = File.join(dir,"#{Time.now.strftime("%Y%m%dT%H%M%S")}订单.xls")
    book.write file_path
    file_path
  end
end