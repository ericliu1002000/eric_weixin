class EricWeixin::Cms::Weixin::ReplyMessageRulesController < EricWeixin::Cms::BaseController
  before_filter :need_login

  def index
    @reply_message_rules = ::EricWeixin::ReplyMessageRule.valid
    @public_accounts = ::EricWeixin::PublicAccount.all
  end

  def new
  end

  def create
   @rule = ::EricWeixin::ReplyMessageRule.create_reply_message_rule params
  end

  def edit
    @rule = ::EricWeixin::ReplyMessageRule.find(params[:id])
    @public_accounts = ::EricWeixin::PublicAccount.all
  end

  def update
    @reply_message_rule = ::EricWeixin::ReplyMessageRule.update_reply_message_rule(params[:id],params[:weixin_reply_message_rule])
  end

  def destroy
    rule = ::EricWeixin::ReplyMessageRule.find(params[:id])
    @rule_id = rule.id
    rule.destroy
  end
end