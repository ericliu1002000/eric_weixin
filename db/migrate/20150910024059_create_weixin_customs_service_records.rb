class CreateWeixinCustomsServiceRecords < ActiveRecord::Migration
  def change
      execute 'CREATE TABLE `weixin_customs_service_records` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `openid` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
                `opercode` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
                `text` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
                `time` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
                `worker` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
                `created_at` datetime DEFAULT NULL,
                `updated_at` datetime DEFAULT NULL,
                `weixin_public_account_id` int(11) DEFAULT NULL,
                PRIMARY KEY (`id`)
              ) ENGINE=InnoDB AUTO_INCREMENT=88 DEFAULT CHARSET=utf8;'
  end
end
