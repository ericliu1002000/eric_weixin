class AlertWeixinReplyMessageRulesSReplyMessageLength < ActiveRecord::Migration
  def change
    change_column :weixin_reply_message_rules, :reply_message, :text
  end
end
