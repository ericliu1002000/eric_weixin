class EricWeixin::Cms::Weixin::CustomsServiceRecordsController < EricWeixin::Cms::BaseController

  def index
    options = params.permit(:public_account_id, :opercode, :chat_date, :chat_content, :worker, :nick_name)
    @customs_service_records = ::EricWeixin::CustomsServiceRecord.common_query options
    @customs_service_records = @customs_service_records.order(:time).paginate(page: params[:page], per_page:20)
  end
end