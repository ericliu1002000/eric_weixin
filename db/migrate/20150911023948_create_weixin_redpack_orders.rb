class CreateWeixinRedpackOrders < ActiveRecord::Migration
  def change
    create_table :weixin_redpack_orders do |t|
      t.integer :weixin_public_account_id
      t.string :mch_billno
      t.string :detail_id
      t.string :send_type
      t.string :hb_type
      t.integer :total_num
      t.integer :total_amount
      t.string :reason
      t.datetime :send_time
      t.datetime :refund_time
      t.integer :refund_amount
      t.string :wishing
      t.string :remark
      t.string :act_name
      t.timestamps
    end
  end
end
