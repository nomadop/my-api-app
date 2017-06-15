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

ActiveRecord::Schema.define(version: 20170615032335) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_booster_creators", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "appid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "appid"], name: "index_account_booster_creators_on_account_id_and_appid", unique: true, using: :btree
  end

  create_table "accounts", force: :cascade do |t|
    t.string   "account_name"
    t.string   "account_id"
    t.text     "cookie"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "booster_creators", force: :cascade do |t|
    t.integer  "appid"
    t.string   "name"
    t.integer  "series"
    t.integer  "price"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "trading_card_type"
    t.boolean  "unavailable",       default: false
    t.string   "available_at_time"
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
    t.index ["buy_orderid"], name: "index_buy_orders_on_buy_orderid", unique: true, using: :btree
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
    t.index ["appid"], name: "index_inventory_descriptions_on_appid", using: :btree
    t.index ["classid", "instanceid"], name: "index_inventory_descriptions_on_classid_and_instanceid", unique: true, using: :btree
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
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.jsonb    "actions"
    t.integer  "goo_value"
    t.integer  "market_fee_app"
    t.string   "name_color"
    t.string   "market_fee"
    t.string   "contained_item"
    t.jsonb    "market_actions"
    t.jsonb    "tags"
    t.jsonb    "item_expiration"
    t.index ["classid"], name: "index_market_assets_on_classid", unique: true, using: :btree
    t.index ["item_nameid"], name: "index_market_assets_on_item_nameid", using: :btree
    t.index ["market_hash_name"], name: "index_market_assets_on_market_hash_name", using: :btree
    t.index ["type"], name: "index_market_assets_on_type", using: :btree
  end

  create_table "my_histories", force: :cascade do |t|
    t.string   "history_id"
    t.string   "who_acted_with"
    t.integer  "price"
    t.string   "classid"
    t.string   "market_hash_name"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["history_id"], name: "index_my_histories_on_history_id", unique: true, using: :btree
    t.index ["market_hash_name"], name: "index_my_histories_on_market_hash_name", using: :btree
  end

  create_table "my_listings", force: :cascade do |t|
    t.string   "listingid"
    t.string   "market_hash_name"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "price"
    t.string   "listed_date"
  end

  create_table "order_histograms", force: :cascade do |t|
    t.string   "item_nameid"
    t.integer  "highest_buy_order"
    t.integer  "lowest_sell_order"
    t.jsonb    "buy_order_graph"
    t.jsonb    "sell_order_graph"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["item_nameid", "created_at"], name: "index_order_histograms_on_item_nameid_and_created_at", using: :btree
  end

  create_table "sell_histories", force: :cascade do |t|
    t.string   "classid"
    t.datetime "datetime"
    t.float    "price"
    t.integer  "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classid", "datetime"], name: "index_sell_histories_on_classid_and_datetime", unique: true, using: :btree
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

end
