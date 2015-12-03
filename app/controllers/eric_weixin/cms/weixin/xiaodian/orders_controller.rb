class EricWeixin::Cms::Weixin::Xiaodian::OrdersController < EricWeixin::Cms::BaseController
  def index
    @orders = EricWeixin::Xiaodian::Order.all
  end

  def save_delivery_info
    begin
    order = EricWeixin::Xiaodian::Order.find_by_id(params[:id])
    if order.blank?
      render text: 'order的ID不正确。'
      return
    end
    options = {}
    options["delivery_company"] = params[:delivery_company]
    options["delivery_track_no"] = params[:delivery_track_no]
    options["need_delivery"] = params[:need_delivery].to_i
    options["is_others"] = params[:is_others].to_i
    result = order.set_delivery options
    render text: result ? '成功' : '失败'
    rescue Exception=>e
      dispose_exception e
      render text: "保存失败: #{get_notice_str}"
    end
  end
end