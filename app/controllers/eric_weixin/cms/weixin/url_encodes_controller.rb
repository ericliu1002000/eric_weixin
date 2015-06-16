class EricWeixin::Cms::Weixin::UrlEncodesController < EricWeixin::Cms::BaseController
  def index
  end

  def create
    params = url_params
    p params[:user]
    if params[:user] == '1'
      @url = EricWeixin::Snsapi.get_snsapi_userinfo_url params
    else
      @url = EricWeixin::Snsapi.get_snsapi_base_url params
    end
    params[:url] = @url
    @short_url = EricWeixin::TwoDimensionCode.short_url params
    respond_to do |format|
      format.js {}
    end
  end
  
  def new
  end

  private
  	def url_params
      params.require('/eric_weixin/cms/weixin/url_encodes').permit(:url, :schema_host, :app_id, :user)
    end
end