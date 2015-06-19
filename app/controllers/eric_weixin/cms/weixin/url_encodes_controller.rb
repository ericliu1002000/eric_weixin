class EricWeixin::Cms::Weixin::UrlEncodesController < EricWeixin::Cms::BaseController
  def index
  end

  def create
    params = url_params
    p params[:details]
    if params[:only_short_url].blank?
      if params[:details] == '1'
        @details_url = EricWeixin::Snsapi.get_snsapi_userinfo_url params
        temp_params = params
        temp_params[:url] = @details_url
        @short_details_url = EricWeixin::TwoDimensionCode.short_url temp_params
      end
      if params[:only_id] == '1'
        @only_id_url = EricWeixin::Snsapi.get_snsapi_base_url params
        temp_params = params
        temp_params[:url] = @only_id_url
        @short_only_id_url = EricWeixin::TwoDimensionCode.short_url temp_params
      end
      if params[:details] == '0' && params[:only_id] == '0'
        @details_url = EricWeixin::Snsapi.get_snsapi_userinfo_url params
        temp_params = params
        temp_params[:url] = @details_url
        @short_details_url = EricWeixin::TwoDimensionCode.short_url temp_params
      end
    else
      params[:url] = params[:only_short_url]
      @short_url = EricWeixin::TwoDimensionCode.short_url params
    end

    respond_to do |format|
      format.js {}
    end
  end

  private
  	def url_params
      params.require('/eric_weixin/cms/weixin/url_encodes').permit(:url, :schema_host, :app_id, :details, :only_id, :only_short_url)
    end
end