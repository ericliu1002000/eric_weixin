class EricWeixin::Xiaodian::Product < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_products'
  has_and_belongs_to_many :categories, :class_name => 'EricWeixin::Xiaodian::Category', :join_table => "weixin_xiaodian_category_products", :foreign_key => :weixin_xiaodian_product_id, association_foreign_key: :weixin_xiaodian_category_id


  # 同步微信小店所有商品
  # EricWeixin::Xiaodian::Product.get_all_products 'rszx'
  def self.get_all_products public_account_name
    account = EricWeixin::PublicAccount.get_public_account_by_name public_account_name
    token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: account.id

    param = {status: 0}
    response = RestClient.post "https://api.weixin.qq.com/merchant/getbystatus?access_token=#{token}", param.to_json
    response = JSON.parse response.body
    if response["errcode"] == 0
      response["products_info"].each do |product_info|
        product = EricWeixin::Xiaodian::Product.create_product product_id: product_info["product_id"],
                                                               name: product_info["product_base"]["name"],
                                                               status: product_info["status"],
                                                               delivery_type: product_info["delivery_info"]["delivery_type"],
                                                               weixin_public_account_id: account.id,
                                                               sku_info: product_info["product_base"]["sku_info"],
                                                               properties: product_info["product_base"]["property"],
                                                               wx_category_id: product_info["product_base"]["category_id"]

        (product_info["sku_list"]||[]).each do |sku|
          EricWeixin::Xiaodian::ProductSkuDetail.create_sku_detail weixin_xiaodian_product_id: product.id,
                                                                   sku_id: sku["sku_id"],
                                                                   icon_url: sku["icon_url"],
                                                                   price: sku["price"],
                                                                   quantity: sku["quantity"],
                                                                   product_code: sku["product_code"],
                                                                   ori_price: sku["ori_price"]
        end

      end
    else
      pp response
      return
    end
  end


  #创建商品
  def self.create_product options
    EricWeixin::Xiaodian::Product.transaction do
      product = EricWeixin::Xiaodian::Product.where(product_id: options[:product_id]).first
      product = if product.blank?
                  EricWeixin::Xiaodian::Product.new product_id: options[:product_id],
                                                    name: options[:name],
                                                    status: options[:status],
                                                    delivery_type: options[:delivery_type],
                                                    sku_info: options[:sku_info],
                                                    properties: options[:properties],
                                                    weixin_public_account_id: options[:weixin_public_account_id]
                else
                  product.name = options[:name]
                  product.status = options[:status]
                  product.delivery_type = options[:delivery_type]
                  product.sku_info= options[:sku_info]
                  product.properties= options[:properties]
                  product
                end
      product.save!

      #更新分类信息
      category_list = (product.categories.collect &:wx_category_id)
      new_category_list = options["wx_category_id"]||[]
      pp category_list
      pp new_category_list
      if not (category_list&new_category_list).length == category_list.length
        product.categories.clear
        options["wx_category_id"].each do |wx_category_id|
          c = EricWeixin::Xiaodian::Category.where(wx_category_id: wx_category_id).first
          product.categories << c
        end
        product.save!
      end
      product
    end
  end
end
__END__
{"errcode"=>0, "errmsg"=>"ok",
 "products_info"=>[
     {"product_base"=>{
         "name"=>"探险活宝－手机壳",
         "category_id"=>[537088786],
         "img"=>[],
         "detail"=>[],
         "property"=>[{"id"=>"品牌", "vid"=>"探险活宝"}, {"id"=>"出售类型", "vid"=>"现货"}, {"id"=>"货号", "vid"=>"AT001"}, {"id"=>"礼盒包装", "vid"=>"否"}, {"id"=>"周边系列", "vid"=>"模型展示盒"}, {"id"=>"热门动漫系列", "vid"=>"探险活宝"}, {"id"=>"是否有导购视频", "vid"=>"无视频"}, {"id"=>"适用年龄", "vid"=>"6岁以上"}, {"id"=>"作品来源", "vid"=>"卡通"}, {"id"=>"按动漫来源", "vid"=>"欧美动漫"}],
         "sku_info"=>[],
         "buy_limit"=>0,
         "main_img"=>"http://mmbiz.qpic.cn/mmbiz/PsD21Mpo7RU2qLuAFZZPemn9icG05gT5lPjmw3LxtGHznicCiaPFx13yaKrPiaOf5QULW1Vm9GJETPTeM3y9h6Wib3w/0?wx_fmt=jpeg",
         "detail_html"=>""
     },
      "sku_list"=>[
          {"sku_id"=>"", "price"=>5000, "icon_url"=>"", "quantity"=>100, "product_code"=>"", "ori_price"=>10000}
      ],
      "delivery_info"=>{
          "delivery_type"=>0, "template_id"=>0, "weight"=>0, "volume"=>0, "express"=>[{"id"=>10000027, "price"=>0}, {"id"=>10000028, "price"=>0}, {"id"=>10000029, "price"=>0}]
      },
      "product_id"=>"pE46BjpxJ_7k_H_LmIr4uWPQUI2Q",
      "status"=>2,
      "attrext"=>{"isPostFree"=>1, "isHasReceipt"=>1, "isUnderGuaranty"=>1, "isSupportReplace"=>0,
                  "location"=>{"country"=>"中国", "province"=>"云南", "city"=>"丽江", "address"=>""}}
     }
 ]
}