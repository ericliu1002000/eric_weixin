class EricWeixin::Xiaodian::SkuName < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_sku_names'
  validates_uniqueness_of :wx_name_id, scope: :weixin_xiaodian_category_id

  #创建sku name
  # 接收参数： name    weixin_name_id   类别id
  def self.create_skuname options
    name = EricWeixin::Xiaodian::SkuName.where(wx_name_id: options[:wx_name_id],
                                               weixin_xiaodian_category_id: options[:weixin_xiaodian_category_id]).first
    name = if name.blank?
             name = EricWeixin::Xiaodian::SkuName.new name: options[:name],
                                                      weixin_xiaodian_category_id: options[:weixin_xiaodian_category_id],
                                                      wx_name_id: options[:wx_name_id]
           else
             name.name = options[:name]
             name
           end
    name.save!
    name
  end


end