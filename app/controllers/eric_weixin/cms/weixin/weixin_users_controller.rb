class EricWeixin::Cms::Weixin::WeixinUsersController < EricWeixin::Cms::BaseController
  def index
    @public_accounts = ::EricWeixin::PublicAccount.all
    public_account = ::EricWeixin::PublicAccount.find_by_id(params[:public_account_id])
    @weixin_users = public_account.weixin_users.custom_query(params.permit(:subscribe,
                                                                           :nickname,
                                                                           :sex,
                                                                           :city,
                                                                           :province,
                                                                           :weixin_public_account_id,
                                                                           :start_date,
                                                                           :end_date)).
        order(id: :desc).
        paginate(page: params[:page]||1, per_page: params[:per_page]||10) unless public_account.blank?
  end

  def modify_remark
    user = ::EricWeixin::WeixinUser.find(params[:id])
    user.set_remark params[:new_remark]
    user.reload
    render text: user.remark
  end
end