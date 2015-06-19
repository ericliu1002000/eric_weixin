class EricWeixin::Cms::Weixin::PublicAccountsController < EricWeixin::Cms::BaseController
      def index
        @public_accounts = ::EricWeixin::PublicAccount.all.paginate(page:params[:page], per_page: 5)
      end
      def show
        @public_account = ::EricWeixin::PublicAccount.find(params[:id])
        @weixin_menus = @public_account.weixin_menus.to_json
      end

      def create_menu
        begin
          @public_account = ::EricWeixin::PublicAccount.find(params[:id])
          @public_account.create_menu params[:menu_json]
        rescue Exception => e
          dispose_exception e
          flash[:alert] = '创建菜单失败，原因：' + get_notice_str
        end

        redirect_to :action => :show
      end

      def rebuild_weixin_users
        @public_account = ::EricWeixin::PublicAccount.find(params[:id])
        @public_account.rebuild_users
        # set_notice("重建成功")
        flash[:success] = "更新用户列表成功。"
        redirect_to :action => :index
      end

      def export
        @public_account = ::EricWeixin::PublicAccount.find(params[:id])
        @csv = EricWeixin::WeixinUser.export_users_to_csv(@public_account.id)
        send_data @csv
      end

end