class EricWeixin::Xiaodian::Order < ActiveRecord::Base
  # require 'barby/barcode/code_128'
  # require 'barby/outputter/png_outputter'

  self.table_name = 'weixin_xiaodian_orders'
  # belongs_to :weixin_user, class_name: "::EricWeixin::WeixinUser"
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

  def weixin_user
    ::EricWeixin::WeixinUser.find_by_openid self.openid
  end

  def product_info
    return '' if self.sku_info.blank?
    info = ""
    list = self.sku_info.split(";")
    list.each do |sku|
      str = sku.split(":")[1]
      return 'error' if str.blank?
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
    # user = EricWeixin::WeixinUser.where(openid: openid).first
    to_user_name = options[:ToUserName]
    account = EricWeixin::PublicAccount.where(weixin_number: to_user_name).first

    product = EricWeixin::Xiaodian::Product.where(product_id: options[:ProductId]).first
    if product.blank?
      EricWeixin::Xiaodian::Product.get_all_products account.name
      product = EricWeixin::Xiaodian::Product.where(product_id: options[:ProductId]).first
    end


    # if user.blank?
    #   account.delay.rebuild_users_simple
    #   # user = EricWeixin::WeixinUser.where(openid: openid).first
    # end

    # user_id = user.blank? ? nil : user.id

    order = EricWeixin::Xiaodian::Order.new order_id: options[:OrderId],

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


  # def buyer_nick
  #   CGI::unescape(self.attributes["buyer_nick"]) rescue '无法正常显示'
  # end

  # 更新指定时间区间的订单信息
  # EricWeixin::Xiaodian::Order.update_order_infos
  def self.update_order_infos start_date, end_date
    self.where("order_create_time between ? and ? ", start_date.to_time.to_i, end_date.to_time.to_i).each do |order|
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
      self.update_attributes order_params.select{|k,v| ['order_id', 'order_status', 'order_total_price', 'order_create_time', 'order_express_price', 'buyer_nick', 'receiver_name', 'receiver_province', 'receiver_city', 'receiver_zone', 'receiver_address', 'receiver_mobile', 'receiver_phone',
                             'product_name', 'product_name', 'product_sku', 'product_count', 'product_img', 'trans_id'].include? k }
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
        orders = EricWeixin::Xiaodian::Order.where order_id: order["order_id"]
        next unless orders.blank?
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
    # pp options
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
      if options["need_delivery"].to_s == "0"
        self.update_attributes delivery_id: "", delivery_company: ""
      else
        self.update_attributes delivery_id: options["delivery_track_no"], delivery_company: options["delivery_company"]
      end
      true
    else
      false
    end
  end

  # need_deliver 1:未发货  0 已发货
  def self.get_excel_of_orders options
    orders = self.order_query options
    # if options[:need_deliver] == '1'
    #   orders = orders.where("delivery_id is null or delivery_id = '' or delivery_company is null or delivery_company = '' ")
    # else
    #   orders = orders.where("delivery_id is not null and delivery_id <> '' and delivery_company is not null and delivery_company <> '' ")
    # end
    orders = orders.order(order_create_time: :desc)

    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: '订单表'
    sheet1.row(0).push '产品名称', '数量', '收货人', '移动电话', '快递公司', '快递单号', '买家昵称', '订单ID', '固定电话', '省', '城市', '区', '地址', '是否是粉丝', '订单时间', '快递费(单位:元)', '总金额(单位:元)'

    current_row = 1
    orders.each do |order|
      wx_user = order.weixin_user
      is_fan =  if !wx_user.blank? && wx_user.subscribe == 1
                  '是'
                else
                  '否'
                end
      sheet1.row(current_row).push (begin order.product.name rescue '' end),
                                   order.product_count,
                                   order.receiver_name,
                                   order.receiver_mobile,
                                   order.delivery_company,
                                   order.delivery_id,
                                   order.buyer_nick,
                                   order.order_id,
                                   order.receiver_phone,
                                   order.receiver_province,
                                   order.receiver_city,
                                   order.receiver_zone,
                                   order.receiver_address,
                                   is_fan,
                                   Time.at(order.order_create_time).strftime("%Y-%m-%d %H:%M:%S"),
                                   order.order_express_price.to_f/100,
                                   order.order_total_price.to_f/100
      current_row += 1
    end
    dir = Rails.root.join('public', 'downloads')
    Dir.mkdir dir unless Dir.exist? dir
    file_path = File.join(dir,"#{Time.now.strftime("%Y%m%dT%H%M%S")}订单.xls")
    book.write file_path
    file_path
  end


  # order查询,支持以下参数:
  #   start_date, end_date  起始日期, 终止日期
  #   buyer_nick 买家昵称
  #   receiver_name 收货人姓名
  #   receiver_mobile 收货人手机
  #   deliver_status 发货状态, (1-未发货, 2-已发货)
  #   delivery_id 快递单号
  #   receiver_address 地址
  #   receiver_city  城市
  def self.order_query options
    orders = self.all
    orders = orders.where("order_create_time >= ?", options[:start_date].to_time.change(hour:0,min:0,sec:0).to_i) unless options[:start_date].blank?
    orders = orders.where("order_create_time <= ?", options[:end_date].to_time.change(hour:23,min:59,sec:59).to_i) unless options[:end_date].blank?
    orders = orders.where("buyer_nick LIKE ?", "%#{options[:buyer_nick]}%") unless options[:buyer_nick].blank?
    orders = orders.where("receiver_name LIKE ?", "%#{options[:receiver_name]}%") unless options[:receiver_name].blank?
    orders = orders.where("receiver_mobile = ?", options[:receiver_mobile]) unless options[:receiver_mobile].blank?
    orders = orders.where("delivery_id like ?", "%#{options[:delivery_id]}%") unless options[:delivery_id].blank?
    orders = orders.where("receiver_address like ?", "%#{options[:receiver_address]}%") unless options[:receiver_address].blank?
    orders = orders.where("receiver_city like ?", "%#{options[:receiver_city]}%") unless options[:receiver_city].blank?
    orders = orders.where("delivery_id is null or delivery_id = '' or delivery_company is null or delivery_company = '' ") if options[:deliver_status] == 1.to_s
    orders = orders.where("delivery_id is not null and delivery_id <> '' and delivery_company is not null and delivery_company <> '' ") if options[:deliver_status] == 2.to_s
    orders
  end

  # 通过excel文件更新微信小店订单快递信息，包括快递公司与快递单号
  def self.update_delivery_info_by_excel file
    self.transaction do
      Spreadsheet.client_encoding = 'UTF-8'
      dir = 'public/temp'
      Dir.mkdir dir unless Dir.exist? dir
      path = Rails.root.join(dir, file.original_filename)
      File.open(path, 'wb') do |f|
        f.write(file.read)
      end
      book = Spreadsheet.open path
      sheet = book.worksheet 0

      # 遍历到订单ID列
      order_id_col = -1
      delivery_company_col = -1
      delivery_order_id_col = -1
      100.times do |i|
        order_id_col = i if sheet.row(0)[i] == '订单ID'
        delivery_company_col = i if sheet.row(0)[i] == '快递公司'
        delivery_order_id_col = i if sheet.row(0)[i] == '快递单号'
        break if order_id_col != -1 && delivery_company_col != -1 && delivery_order_id_col != -1
      end

      BusinessException.raise '请确保excel文件第一列包含以下列名：订单ID、快递公司、快递单号' if order_id_col == -1 || delivery_company_col == -1 || delivery_order_id_col == -1
      success_count = 0
      total_count = 0
      sheet.each_with_index do |row, index|
        next if index == 0
        total_count += 1
        # 以下几种情况会跳过
        # * 订单ID不正确
        # * 没有快递公司
        # * 没有快递单号
        # * 数据库中快递小店订单的快递公司已经存在
        # * 数据库中快递小店订单的快递单号已经存在
        order_id = row[order_id_col]
        xiaodian_order = self.find_by_order_id(order_id)
        next if xiaodian_order.blank?
        next if row[delivery_company_col].blank? || row[delivery_order_id_col].blank?
        next if !xiaodian_order.delivery_company.blank? || !xiaodian_order.delivery_id.blank?

        # 过五关、斩六将后，终于可以更新快递信息了
        delivery_order_id = row[delivery_order_id_col].is_a?(Float) ? row[delivery_order_id_col].to_i.to_s : row[delivery_order_id_col].to_s
        options = {
            "delivery_company" => row[delivery_company_col].to_s,
            "delivery_track_no" => delivery_order_id,
            "need_delivery" => 1,
            "is_others" => 1
        }
        result = xiaodian_order.set_delivery options
        success_count += 1 if result
      end
      # 删除临时文件
      File.delete path
      "共#{total_count}条记录，更新成功#{success_count}条。"
    end
  end

  # 生成订单的快递号条码, 图片保存在 ddc_system/public/uploads/barcode/ 文件夹中, 需要定时清除!
  def delivery_id_barcode
    delivery_id = self.delivery_id
    file_name = "order_delivery_id_#{delivery_id}.png"
    options = {
        :content => delivery_id.to_s,
        :file_path => Rails.root.join('public', 'uploads/barcode', file_name)
    }
    BarbyTools.create_barcode options # 使用tools里面的方法,代替下面这个注释过的代码块
    # barcode = Barby::Code128B.new(delivery_id.to_s)
    # blob = Barby::PngOutputter.new(barcode).to_png(:height => 20, :margin => 5) # 初始png数据
    # file_path = Rails.root.join('public', 'uploads/barcode', file_name)
    # File.open(file_path, 'wb'){|f|
    #   f.write blob.force_encoding("ISO-8859-1")
    # }
    simple_file_path = "/uploads/barcode/#{file_name}"
    simple_file_path
  end

end