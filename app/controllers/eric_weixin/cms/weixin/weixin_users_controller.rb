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
                                                                           :end_date,
                                                             :first_register_channel,
                                                             :last_register_channel)).
        order(id: :desc).
        paginate(page: params[:page]||1, per_page: params[:per_page]||10) unless public_account.blank?
  end

  def modify_remark
    user = ::EricWeixin::WeixinUser.find(params[:id])
    user.set_remark params[:new_remark]
    user.reload
    render text: user.remark
  end

  def quick_get_user_infos
    public_account = ::EricWeixin::PublicAccount.find(params[:public_account_id])
    if public_account.blank?
      flash[:alert] = '未指定公众账号'
      redirect_to action: :index
      return
    end
    public_account.delay(:priority => 10).rebuild_users_simple
    flash[:success] = '已经把快速更新微信用户信息任务添加到队列任务中'
    redirect_to action: :index
  end

  def batch_update_user_infos
    public_account = ::EricWeixin::PublicAccount.find(params[:public_account_id])
    if public_account.blank?
      flash[:alert] = '未指定公众账号'
      redirect_to action: :index
      return
    end
    public_account.delay(:priority => 10).update_users
    flash[:success] = '已经把批量更新微信用户信息任务添加到队列任务中'
    redirect_to action: :index
  end
end