class CreateWeixinXiaodianCategory < ActiveRecord::Migration
  def change
    create_table :weixin_xiaodian_categories do |t|
      t.integer :parent_id
      t.string :name
      t.string :wx_category_id
    end
  end
end
