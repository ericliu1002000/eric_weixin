class EricWeixin::Cms::Weixin::NewsDatasController < EricWeixin::Cms::BaseController
      def index
        @news_datas = ::EricWeixin::News.all
      end

      def show
        @news_data = ::EricWeixin::News.find(params[:id])
      end

      def edit
        @news_data = ::EricWeixin::News.find(params[:id])
      end

      def create
        begin
          @news_data = ::EricWeixin::News.create_news_datas( weixin_news_data_param,
                                                             params[:weixin_news][:weixin_article_data_ids],
                                                             params[:weixin_news][:weixin_article_data_sort]
          )
          redirect_to "/eric_weixin/cms/weixin/news_datas/#{@news_data.id}/edit", notice: '微信图文消息创建成功.'
        rescue Exception => e
          render :edit
        end
      end

      def new
        @news_data = ::EricWeixin::News.new
      end

      def update
        begin
          @news_data = ::EricWeixin::News.update_news_datas(params[:id],
                                                            weixin_news_data_param,
                                                            params[:weixin_news][:weixin_article_data_ids],
                                                            params[:weixin_news][:weixin_article_data_sort]
          )

          redirect_to "/eric_weixin/cms/weixin/news_datas/#{@news_data.id}/edit", notice: '微信图文消息更新成功.'
        rescue Exception => e
          render :edit
        end
      end

      private
      def set_weixin_news_data
        @weixin_news = ::EricWeixin::News.find(params[:id])
      end

      def weixin_news_data_param
        params.require(:weixin_news).permit(:title, :match_key)
      end
end