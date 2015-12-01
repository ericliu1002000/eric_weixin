class EricWeixin::Xiaodian::Order < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_orders'

  # 接收订单
  def self.create_order options
    order = EricWeixin::Xiaodian::Order.where(order_id: options[:OrderId]).first
    return unless order.blank?

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
  end
end