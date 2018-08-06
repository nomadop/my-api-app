# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180806100529) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_booster_creators", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "appid"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "unavailable",       default: false
    t.string   "available_at_time"
    t.index ["account_id", "appid"], name: "index_account_booster_creators_on_account_id_and_appid", unique: true, using: :btree
  end

  create_table "account_histories", force: :cascade do |t|
    t.integer  "account_id"
    t.datetime "date"
    t.string   "type"
    t.string   "payment"
    t.integer  "total"
    t.integer  "change"
    t.integer  "balance"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.jsonb    "items"
    t.string   "total_text"
    t.string   "change_text"
    t.string   "balance_text"
    t.boolean  "refunded"
  end

  create_table "accounts", force: :cascade do |t|
    t.string   "account_name"
    t.string   "account_id"
    t.text     "cookie"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "email_address"
    t.string   "email_password"
    t.integer  "status",              default: 0
    t.string   "bot_name"
    t.integer  "tradable_goo_amount"
    t.index ["account_id"], name: "index_accounts_on_account_id", unique: true, using: :btree
  end

  create_table "admins", force: :cascade do |t|
    t.string   "email",                        null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.index ["email"], name: "index_admins_on_email", unique: true, using: :btree
    t.index ["remember_me_token"], name: "index_admins_on_remember_me_token", using: :btree
  end

  create_table "booster_creations", force: :cascade do |t|
    t.integer  "account_id",         null: false
    t.integer  "booster_creator_id", null: false
    t.string   "communityitemid"
    t.integer  "appid"
    t.integer  "item_type"
    t.string   "purchaseid"
    t.integer  "success"
    t.integer  "rwgrsn"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["booster_creator_id"], name: "index_booster_creations_on_booster_creator_id", using: :btree
  end

  create_table "booster_creators", force: :cascade do |t|
    t.integer  "appid"
    t.string   "name"
    t.integer  "series"
    t.integer  "price"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "trading_card_type"
    t.boolean  "unavailable",             default: false
    t.string   "available_at_time"
    t.integer  "booster_creations_count"
    t.float    "base_ppg"
    t.index ["appid"], name: "index_booster_creators_on_appid", unique: true, using: :btree
  end

  create_table "buy_orders", force: :cascade do |t|
    t.string   "buy_orderid"
    t.integer  "active"
    t.integer  "purchased"
    t.jsonb    "purchases"
    t.integer  "quantity"
    t.integer  "quantity_remaining"
    t.integer  "success"
    t.string   "market_hash_name"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "price"
    t.text     "purchase_amount_text"
    t.integer  "account_id"
    t.index ["buy_orderid"], name: "index_buy_orders_on_buy_orderid", unique: true, using: :btree
  end

  create_table "emails", force: :cascade do |t|
    t.string   "from"
    t.string   "to"
    t.string   "message_id"
    t.string   "subject"
    t.text     "body"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_emails_on_date", using: :btree
    t.index ["message_id"], name: "index_emails_on_message_id", unique: true, using: :btree
    t.index ["to"], name: "index_emails_on_to", using: :btree
  end

  create_table "friends", force: :cascade do |t|
    t.string   "profile"
    t.string   "account_id"
    t.string   "account_name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "profile_url"
    t.string   "steamid"
    t.index ["profile"], name: "index_friends_on_profile", unique: true, using: :btree
  end

  create_table "inventory_assets", force: :cascade do |t|
    t.string   "appid"
    t.string   "amount"
    t.string   "assetid"
    t.string   "classid"
    t.string   "contextid"
    t.string   "instanceid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "account_id"
    t.index ["assetid"], name: "index_inventory_assets_on_assetid", unique: true, using: :btree
  end

  create_table "inventory_descriptions", force: :cascade do |t|
    t.json     "actions"
    t.integer  "appid"
    t.string   "background_color"
    t.string   "classid"
    t.integer  "commodity"
    t.integer  "currency"
    t.json     "descriptions"
    t.string   "icon_url"
    t.string   "icon_url_large"
    t.string   "instanceid"
    t.string   "market_hash_name"
    t.integer  "market_marketable_restriction"
    t.string   "market_name"
    t.integer  "market_tradable_restriction"
    t.integer  "marketable"
    t.string   "name"
    t.json     "owner_actions"
    t.json     "tags"
    t.integer  "tradable"
    t.string   "type"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.json     "owner_descriptions"
    t.integer  "market_fee_app"
    t.string   "item_expiration"
    t.index ["appid"], name: "index_inventory_descriptions_on_appid", using: :btree
    t.index ["classid", "instanceid"], name: "index_inventory_descriptions_on_classid_and_instanceid", unique: true, using: :btree
  end

  create_table "job_concurrences", force: :cascade do |t|
    t.string   "uuid",                       null: false
    t.integer  "limit_type", default: 0
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "limit"
    t.string   "job_id"
    t.boolean  "delegated",  default: false
    t.index ["uuid", "limit"], name: "index_job_concurrences_on_uuid_and_limit", unique: true, using: :btree
  end

  create_table "market_assets", id: false, force: :cascade do |t|
    t.string   "amount"
    t.string   "app_icon"
    t.integer  "appid"
    t.string   "background_color"
    t.string   "classid"
    t.integer  "commodity"
    t.string   "contextid"
    t.integer  "currency"
    t.jsonb    "descriptions"
    t.string   "icon_url"
    t.string   "icon_url_large"
    t.string   "instanceid"
    t.string   "market_hash_name"
    t.string   "market_marketable_restriction"
    t.string   "market_name"
    t.string   "market_tradable_restriction"
    t.integer  "marketable"
    t.string   "name"
    t.string   "original_amount"
    t.integer  "owner"
    t.jsonb    "owner_actions"
    t.integer  "status"
    t.integer  "tradable"
    t.string   "type"
    t.string   "item_nameid"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.jsonb    "actions"
    t.integer  "goo_value"
    t.integer  "market_fee_app"
    t.string   "name_color"
    t.string   "market_fee"
    t.string   "contained_item"
    t.jsonb    "market_actions"
    t.jsonb    "tags"
    t.jsonb    "item_expiration"
    t.string   "unowned_id"
    t.string   "unowned_contextid"
    t.string   "rollback_new_id"
    t.string   "rollback_new_contextid"
    t.integer  "order_owner_id"
    t.integer  "sell_volume",                   default: 0
    t.index ["classid"], name: "index_market_assets_on_classid", unique: true, using: :btree
    t.index ["item_nameid"], name: "index_market_assets_on_item_nameid", using: :btree
    t.index ["market_hash_name"], name: "index_market_assets_on_market_hash_name", using: :btree
    t.index ["order_owner_id"], name: "index_market_assets_on_order_owner_id", using: :btree
    t.index ["type"], name: "index_market_assets_on_type", using: :btree
  end

  create_table "my_histories", force: :cascade do |t|
    t.string   "history_id"
    t.string   "who_acted_with"
    t.integer  "price"
    t.string   "classid"
    t.string   "market_hash_name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "market_listing_name"
    t.integer  "account_id"
    t.string   "listed_date"
    t.index ["history_id"], name: "index_my_histories_on_history_id", unique: true, using: :btree
    t.index ["market_hash_name"], name: "index_my_histories_on_market_hash_name", using: :btree
  end

  create_table "my_listings", force: :cascade do |t|
    t.string   "listingid"
    t.string   "market_hash_name"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "price"
    t.string   "listed_date"
    t.boolean  "confirming",       default: false
    t.integer  "account_id",       default: 1
  end

  create_table "order_activities", force: :cascade do |t|
    t.string   "item_nameid"
    t.string   "content"
    t.string   "user1_name"
    t.string   "user1_avatar"
    t.string   "user2_name"
    t.string   "user2_avatar"
    t.integer  "price"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["content"], name: "index_order_activities_on_content", unique: true, using: :btree
  end

  create_table "order_histogram_histories", force: :cascade do |t|
    t.string   "item_nameid"
    t.integer  "highest_buy_order"
    t.integer  "lowest_sell_order"
    t.datetime "created_at"
    t.index ["item_nameid"], name: "index_order_histogram_histories_on_item_nameid", using: :btree
  end

  create_table "order_histograms", force: :cascade do |t|
    t.string   "item_nameid"
    t.integer  "highest_buy_order"
    t.integer  "lowest_sell_order"
    t.jsonb    "buy_order_graph"
    t.jsonb    "sell_order_graph"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "cached_highest_buy"
    t.integer  "cached_lowest_buy"
    t.integer  "cached_highest_sell"
    t.integer  "cached_lowest_sell"
    t.integer  "schedule_interval",   default: 21600
    t.index ["item_nameid"], name: "index_order_histograms_on_item_nameid", unique: true, using: :btree
  end

  create_table "sell_histories", force: :cascade do |t|
    t.string   "classid"
    t.datetime "datetime"
    t.float    "price"
    t.integer  "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classid"], name: "index_sell_histories_on_classid", using: :btree
  end

  create_table "steam_apps", force: :cascade do |t|
    t.string   "type"
    t.string   "name"
    t.integer  "steam_appid"
    t.boolean  "is_free"
    t.jsonb    "categories"
    t.jsonb    "genres"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["steam_appid"], name: "index_steam_apps_on_steam_appid", unique: true, using: :btree
  end

  create_table "steam_users", force: :cascade do |t|
    t.string   "account_id"
    t.string   "account_name"
    t.string   "profile_url"
    t.string   "steamid"
    t.string   "nickname"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "country"
    t.string   "avatar_name"
    t.index ["steamid"], name: "index_steam_users_on_steamid", unique: true, using: :btree
  end

  create_table "trade_offers", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "trade_offer_id"
    t.string   "partner_id"
    t.string   "partner_name"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "status",            default: 0
    t.integer  "your_offer_count"
    t.integer  "their_offer_count"
    t.string   "status_desc"
    t.index ["trade_offer_id"], name: "index_trade_offers_on_trade_offer_id", unique: true, using: :btree
  end

end
