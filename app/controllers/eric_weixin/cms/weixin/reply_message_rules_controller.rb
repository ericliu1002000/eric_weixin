class EricWeixin::Cms::Weixin::ReplyMessageRulesController < EricWeixin::Cms::BaseController
  before_filter :need_login

  def index
    @reply_message_rules = ::EricWeixin::ReplyMessageRule.valid.paginate(page: params[:page], per_page:params[:per_page]||10)
    @public_accounts = ::EricWeixin::PublicAccount.all
  end

  def new
    @public_accounts = ::EricWeixin::PublicAccount.all
  end

  def create
    begin
      ::EricWeixin::ReplyMessageRule.create_reply_message_rule params
      flash[:success] = "创建成功。"
      redirect_to action: :index
    rescue Exception=>e
      dispose_exception e
      flash.now[:alert] = get_notice_str
      @public_accounts = ::EricWeixin::PublicAccount.all
      render :new
    end
  end

  def edit
    @rule = ::EricWeixin::ReplyMessageRule.find(params[:id])
    @public_accounts = ::EricWeixin::PublicAccount.all
  end

  def update
    begin
      @reply_message_rule = ::EricWeixin::ReplyMessageRule.update_reply_message_rule(params[:id],params)
      flash[:success] = "更新成功。"
      redirect_to action: :index
    rescue Exception=> e
      dispose_exception e
      flash.now[:alert] = get_notice_str
      @public_accounts = ::EricWeixin::PublicAccount.all
      render :edit
    end
  end

  def destroy
    rule = ::EricWeixin::ReplyMessageRule.find(params[:id])
    @rule_id = rule.id
    rule.destroy
  end
end