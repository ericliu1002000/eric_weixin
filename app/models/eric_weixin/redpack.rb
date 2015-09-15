class EricWeixin::Redpack < ActiveRecord::Base
  self.table_name = 'weixin_redpacks'

  belongs_to :redpack_order, foreign_key: 'weixin_redpack_order_id'

  STATUS = {
      "SENDING" => "发放中",
      "SENT" => "已发放待领取",
      "FAILED"=>"发放失败",
      "RECEIVED"=>"已领取",
      "REFUND"=>"已退款"
  }

  def self.create_redpack options
    self.transaction do
      redpack = self.new status: options[:status],
               openid: options[:openid],
               amount: options[:amount],
               rcv_time: options[:rcv_time]
      redpack.save!
      redpack
    end
  end

end