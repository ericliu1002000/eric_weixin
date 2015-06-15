class EricWeixin::Cms::Weixin::ArticleDatasController < EricWeixin::Cms::BaseController
      before_action :set_weixin_article_data, only: [:show, :edit, :update, :destroy]
      def index
        @article_datas = ::EricWeixin::Article.all
      end

      def new
        @article_data = ::EricWeixin::Article.new
      end

      def show

      end


      def edit
      end


      def create
        begin
          @article_data = ::EricWeixin::Article.create_article_data(weixin_article_data_params)
          redirect_to "/eric_weixin/cms/weixin/article_datas/#{@article_data.id}"
        rescue Exception => e
          set_notice "参数输入有错"
          redirect_to "/eric_weixin/cms/weixin/article_datas/new"
        end
      end

      def update
        pp params
        @article_data.update(weixin_article_data_params)
        render :edit
      end


      private
      def set_weixin_article_data
        @article_data = ::EricWeixin::Article.find(params[:id])
      end

      def weixin_article_data_params
        params.require(:article).permit(:title, :desc, :pic_url, :link_url)
      end
end