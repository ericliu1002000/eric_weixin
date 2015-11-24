class EricWeixin::Xiaodian::SkuValue < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_sku_values'

  #创建sku name
  # 接收参数： name    weixin_value_id   类别id
  def self.create_sku_value options
    v = EricWeixin::Xiaodian::SkuValue.where(wx_value_id: options[:wx_value_id],
                                             weixin_xiaodian_sku_name_id: options[:weixin_xiaodian_sku_name_id]).first
    v = if v.blank?
          v = EricWeixin::Xiaodian::SkuValue.new name: options[:name],
                                                 weixin_xiaodian_sku_name_id: options[:weixin_xiaodian_sku_name_id],
                                                 wx_value_id: options[:wx_value_id]
        else
          v.name = options[:name]
          v
        end
    v.save!
    v
  end
end