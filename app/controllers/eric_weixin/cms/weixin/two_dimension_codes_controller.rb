class EricWeixin::Cms::Weixin::TwoDimensionCodesController < EricWeixin::Cms::BaseController
  # before_action :set_weixin_article_data, only: [:show, :edit, :update, :destroy]
  def index
  	@two_dimension_codes = ::EricWeixin::TwoDimensionCode.where("action_info <> ?", '')
  end

  def show
  	@two_dimension_code = ::EricWeixin::TwoDimensionCode.find(params[:id])
  end

  def create
  	begin
      @two_dimension_code = ::EricWeixin::TwoDimensionCode.get_long_time_two_dimension_code(two_dimension_code_params)
      redirect_to cms_weixin_two_dimension_code_path(@two_dimension_code.id)
    rescue Exception => e
      dispose_exception e
      message = get_notice_str
      redirect_to new_cms_weixin_two_dimension_code_path
    end
  end

  def new
  	@two_dimension_code = ::EricWeixin::TwoDimensionCode.new
  	@public_accounts = ::EricWeixin::PublicAccount.all
  end

  private
	def find_two_dimension_code
	  @two_dimension_code = ::EricWeixin::TwoDimensionCode.find(params[:id])
	end

	def two_dimension_code_params
	  params.require(:two).permit(:action_info, :scene_str, :app_id)
	end

end