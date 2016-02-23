EricWeixin::Engine.routes.draw do
  get "/weixin/service/:app_id" => "wz/weixin#index"
  post "/weixin/service/:app_id" => "wz/weixin#reply"
  get "/weixin/service1/ddd" => "wz/weixin#aa"
  get "/weixin/snsapi" => "wz/weixin#snsapi_api"
  get "/weixin/snsuserinfo" => "wz/weixin#snsapi_userinfo"

  get "/weixin/pay" => "wz/pays#prepay"

  get "/weixin/orders" => "wz/xiaodian/orders#index"

  namespace :cms do
    namespace :weixin do
      namespace :xiaodian do
        resources :orders do
          collection do
            post :save_delivery_info
            get :download_orders
            get :update_hb_infos
            get :update_order_infos
          end
        end
        resources :products do
          collection do
            get :get_all_products
          end
        end
      end
      resources :public_accounts do
        member do
          get :rebuild_weixin_users
          get :export
          post :create_menu
        end
      end
      resources :weixin_users do
        collection do
          get :quick_get_user_infos
          get :batch_update_user_infos
        end
        member do
          post :modify_remark
        end
      end

      resources :article_datas
      resources :news_datas
      resources :users do
        member do
          post :modify_remark
        end
      end
      resources :reply_message_rules
      resources :two_dimension_codes
      resources :url_encodes
      resources :customs_service_records

      resources :media_resources
      resources :media_articles do
        collection do
          get :select_pic
        end
      end

      resources :media_news do
        collection do
          get :query_media_articles
          get :will_send_articles
          post :save_news
          post :preview
          post :send_news_now
          get :query_weixin_users
        end
      end
    end
  end
end
