class EricWeixin::Xiaodian::Category < ActiveRecord::Base
  self.table_name = 'weixin_xiaodian_categories'
  belongs_to :parent, class_name: EricWeixin::Xiaodian::Category, foreign_key: :parent_id
  has_and_belongs_to_many :products, :class_name => 'EricWeixin::Xiaodian::Product', :join_table => "weixin_xiaodian_category_products", :foreign_key => :weixin_xiaodian_category_id

  validates_uniqueness_of :wx_category_id
  require "rest-client"

  # 把所有的产品类型导入数据库。
  # public_account_name: 公众账号名称
  # parent_id: 分类腾讯id#
  # EricWeixin::Xiaodian::Category.import_all_categories 'rszx', 1
  # EricWeixin::Xiaodian::Category.import_all_categories 'rszx', ['538088633','538071212'], 1   # 玩具、模型等, 食品/茶叶/特产/滋补品
  def self.import_all_categories public_account_name, first_level_weixin_id = [], parent_id = 1
    EricWeixin::Xiaodian::Category.transaction do
      account = EricWeixin::PublicAccount.get_public_account_by_name public_account_name
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: account.id
      param = {:cate_id => parent_id}
      response = RestClient.post "https://api.weixin.qq.com/merchant/category/getsub?access_token=#{token}", param.to_json
      response = JSON.parse response.body
      pp response
      return if response['errcode'].to_i != 0
      response['cate_list'].each do |category_info|
        pid = if parent_id == 1
                0
              else
                c = EricWeixin::Xiaodian::Category.where(wx_category_id: parent_id).first
                c.id
              end
        if pid == 0
          next unless first_level_weixin_id.include? category_info["id"]
        end
        EricWeixin::Xiaodian::Category.create_new_category name: category_info["name"],
                                                           wx_category_id: category_info["id"],
                                                           parent_id: pid
        EricWeixin::Xiaodian::Category.import_all_categories public_account_name,[], category_info["id"]
      end
    end
  end


  # EricWeixin::Xiaodian::Category.update_sku_info 'rszx'
  def self.update_sku_info public_account_name
    EricWeixin::Xiaodian::Category.transaction do
      account = EricWeixin::PublicAccount.get_public_account_by_name public_account_name
      token = ::EricWeixin::AccessToken.get_valid_access_token public_account_id: account.id
      EricWeixin::Xiaodian::Category.all.each do |category|
        next if category.level < 4
        pp '.....................'
        param = {:cate_id => category.wx_category_id.to_i}
        pp param.to_json
        response = RestClient.post "https://api.weixin.qq.com/merchant/category/getsku?access_token=#{token}", param.to_json
        pp 'xxxxxxxx 请求回来了'
        response = JSON.parse response.body
        pp response
        next if response['errcode'] != 0
        response['sku_table'].each do |sku_info|
          name = EricWeixin::Xiaodian::SkuName.create_skuname wx_name_id: sku_info["id"],
                                                              name: sku_info["name"],
                                                              weixin_xiaodian_category_id: category.id
          sku_info["value_list"].each do |value|
            EricWeixin::Xiaodian::SkuValue.create_sku_value wx_value_id: value["id"],
                                                            name: value["name"],
                                                            weixin_xiaodian_sku_name_id: name.id
          end
        end
      end
    end
  end

  def level
    first_p = self.parent
    return 1 if first_p.blank?
    second_p  = first_p.parent
    return 2 if second_p.blank?
    third_p = second_p.parent
    return 3 if third_p.blank?
    return 4
  end


  # 创建商品分类，参数为：名称，微信id， 父类id
  # 父类id，如果不存在则为0
  def self.create_new_category options
    EricWeixin::Xiaodian::Category.transaction do
      category = EricWeixin::Xiaodian::Category.where(wx_category_id: options[:wx_category_id]).first
      if category.blank?
        category = EricWeixin::Xiaodian::Category.new name: options[:name],
                                                      parent_id: options[:parent_id],
                                                      wx_category_id: options[:wx_category_id]
      else
        category.name = options[:name]
      end
      category.save!
      return category
    end
  end
end