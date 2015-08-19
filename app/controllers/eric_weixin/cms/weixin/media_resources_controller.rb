class EricWexin::Cms::Weixin::MediaResourcesController < EricWeixin::Cms::BaseController

  def index
    @media_resources = ::EricWeixin::Weixin.all.order(:id)
    @media_resources = @media_resources.where("tags like ?", "%#{params[:tag]}%") unless params[:tag].blank?
    @media_resources = @media_resources.where(category_name: params[:category_name]) unless params[:category_name].blank?
    @media_resources = @media_resources.paginate(per_page: params[:per_page]||10, page: params[:page]||1)
  end

  def new
    @media_resource = ::EricWeixin::MediaResource.new
  end

  def create
    begin

    rescue Exception=> e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to action: :new, session_content_id: set_session_content
    end
  end

  def edit
    @media_resource = ::EricWeixin::MediaResource.find_by_id(params[:id])
  end

  def update
    begin

    rescue Exception=>e
      dispose_exception e
      flash[:alert] = get_notice_str
      redirect_to "/eric_weixin/cms/weixin/media_resources/#{params[:id]}/edit?session_content_id=#{set_session_content}"
    end
  end

end