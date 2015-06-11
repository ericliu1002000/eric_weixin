class CreateWeixinReportUserData < ActiveRecord::Migration
  def change
    create_table :weixin_report_user_data do |t|
      t.date :ref_date
      t.integer :user_source
      t.integer :new_user
      t.integer :cancel_user
      t.integer :cumulate_user
      t.integer :weixin_public_account_id

      t.timestamps
    end
  end
end
