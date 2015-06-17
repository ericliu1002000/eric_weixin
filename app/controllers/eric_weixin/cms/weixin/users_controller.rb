class EricWeixin::Cms::Weixin::UsersController < EricWeixin::Cms::BaseController
  def index
  	
  end

  def create
    pp '11111111111111111111111111111111111'
    pp params
    pp '11111111111111111111111111111111111'
  	params = user_params
  	@user = ::EricWeixin::WeixinUser.search_weixin_user params
  	pp @user
  	respond_to do |format|
      format.js {}
    end
  end

  private
  	def user_params
      params.require('/eric_weixin/cms/weixin/users').permit(:id, :openid, :sex, :nickname, :language, :city, :province, :country, :subscribe_time_start, :subscribe, :subscribe_time_end, :created_at_start, :created_at_end, :updated_at_start, :updated_at_end, :remark, :member_info_id, :weixin_public_account_id, :last_register_channel, :first_register_channel)
    end
end