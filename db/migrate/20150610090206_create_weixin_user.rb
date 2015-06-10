class CreateWeixinUser < ActiveRecord::Migration
  def change
    execute 'CREATE TABLE `weixin_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subscribe` int(11) DEFAULT NULL,
  `openid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nickname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sex` int(11) DEFAULT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `province` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `headimgurl` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `subscribe_time` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `remark` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `member_info_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `weixin_public_account_id` int(11) DEFAULT NULL,
  `last_register_channel` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_register_channel` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_weixin_users_on_member_info_id` (`member_info_id`) USING BTREE,
  KEY `index_weixin_users_on_nickname` (`nickname`) USING BTREE,
  KEY `index_weixin_users_on_openid` (`openid`) USING BTREE,
  KEY `index_weixin_users_on_subscribe` (`subscribe`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'

    execute 'CREATE TABLE `weixin_two_dimension_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weixin_public_account_id` int(11) DEFAULT NULL,
  `expire_seconds` int(11) DEFAULT NULL,
  `action_name` varchar(30) DEFAULT NULL,
  `action_info` varchar(200) DEFAULT NULL,
  `scene_id` int(11) DEFAULT NULL,
  `scene_str` varchar(64) DEFAULT NULL,
  `ticket` varchar(100) DEFAULT NULL,
  `url` varchar(500) DEFAULT NULL,
  `expire_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;'


  execute 'CREATE TABLE `weixin_template_message_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `openid` varchar(100) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `topcolor` varchar(20) DEFAULT NULL,
  `data` text,
  `message_id` varchar(50) DEFAULT NULL,
  `error_code` varchar(10) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `template_id` varchar(50) DEFAULT NULL,
  `weixin_public_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;'


    execute 'CREATE TABLE `weixin_reply_message_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key_word` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `reply_message` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_word_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_valid` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `order` int(11) DEFAULT NULL,
  `reply_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `weixin_public_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_weixin_reply_message_rules_on_is_valid` (`is_valid`) USING BTREE,
  KEY `index_weixin_reply_message_rules_on_key_word` (`key_word`) USING BTREE,
  KEY `index_weixin_reply_message_rules_on_key_word_type` (`key_word_type`) USING BTREE,
  KEY `index_weixin_reply_message_rules_on_order` (`order`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'


    execute 'CREATE TABLE `weixin_public_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weixin_secret_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `weixin_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `weixin_app_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `menu_json` text COLLATE utf8_unicode_ci,
  `weixin_number` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_weixin_public_accounts_on_weixin_secret_key` (`weixin_secret_key`) USING BTREE,
  KEY `index_weixin_public_accounts_on_weixin_token` (`weixin_token`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'

  execute 'CREATE TABLE `weixin_news` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `match_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'

    execute 'CREATE TABLE `weixin_message_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `openid` varchar(100) DEFAULT NULL,
  `message_type` varchar(30) DEFAULT NULL,
  `message_id` varchar(50) DEFAULT NULL,
  `data` text,
  `account_receive_flg` int(11) DEFAULT NULL,
  `passive_reply_message` text,
  `process_status` int(11) DEFAULT NULL,
  `event_name` varchar(30) DEFAULT NULL,
  `create_time` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `event_key` varchar(600) DEFAULT NULL,
  `weixin_public_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8;'

    execute 'CREATE TABLE `weixin_articles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `desc` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pic_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `link_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'

    execute 'CREATE TABLE `weixin_article_news` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weixin_article_id` int(11) DEFAULT NULL,
  `weixin_news_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'

  execute 'CREATE TABLE `weixin_access_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `access_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expired_at` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `public_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_weixin_access_tokens_on_access_token` (`access_token`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'
  end
end
