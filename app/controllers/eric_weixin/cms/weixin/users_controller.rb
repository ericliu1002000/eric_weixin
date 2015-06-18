class EricWeixin::Cms::Weixin::UsersController < EricWeixin::Cms::BaseController
  def index
    pp user_params
    @user = ::EricWeixin::WeixinUser.search_weixin_user(user_params).paginate(:page => params[:page], :per_page => 2)
  end

  def create
  	params = user_params
  	@user = ::EricWeixin::WeixinUser.search_weixin_user(params).paginate(:page => params[:page], :per_page => 2)
  	pp @user
  	respond_to do |format|
      format.js {}
    end
  end

  def modify_remark
    user = ::EricWeixin::WeixinUser.find(params[:id])
    user.set_remark params[:new_remark]
    user.reload
    render text: user.remark
  end

  private
  	def user_params
      params.permit(:id, :openid, :sex, :nickname, :language, :city, :province, :country, :subscribe_time_start, :subscribe, :subscribe_time_end, :created_at_start, :created_at_end, :updated_at_start, :updated_at_end, :remark, :member_info_id, :weixin_public_account_id, :last_register_channel, :first_register_channel)
    end
end