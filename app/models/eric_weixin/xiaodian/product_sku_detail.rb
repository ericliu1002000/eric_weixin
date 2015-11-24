class EricWeixin::Xiaodian::ProductSkuDetail < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_product_sku_details'


  def self.create_sku_detail options
    detail = EricWeixin::Xiaodian::ProductSkuDetail.where(weixin_xiaodian_product_id: options[:weixin_xiaodian_product_id],
                                                          sku_id: options[:sku_id]).first
    if detail.blank?
      detail = EricWeixin::Xiaodian::ProductSkuDetail.new weixin_xiaodian_product_id: options[:weixin_xiaodian_product_id],
                                                 sku_id: options[:sku_id]
    end
    [:price, :icon_url, :quantity, :product_code, :ori_price]
    detail.price = options[:price]
    detail.icon_url = options[:icon_url]
    detail.quantity = options[:quantity]
    detail.product_code = options[:product_code]
    detail.save!

    unless detail.sku_id.blank?
      sku_wx_name_id, sku_wx_value_id = detail.sku_id.split(':')
      name = EricWeixin::Xiaodian::SkuName.where(wx_name_id: sku_wx_name_id).first
      value = EricWeixin::Xiaodian::SkuValue.where(wx_value_id: sku_wx_value_id).first
      if !name.blank? and !value.blank?
        detail.weixin_xiaodian_sku_name_id = name.id
        detail.weixin_xiaodian_sku_value_id = value.id
        detail.save!
      end
    end
  end



end