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

ActiveRecord::Schema.define(version: 20170315085538) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "booster_creators", force: :cascade do |t|
    t.integer  "appid"
    t.string   "name"
    t.integer  "series"
    t.integer  "price"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "trading_card_type"
    t.index ["appid"], name: "index_booster_creators_on_appid", unique: true, using: :btree
  end

  create_table "buy_orders", force: :cascade do |t|
    t.string   "buy_orderid"
    t.integer  "active"
    t.integer  "purchased"
    t.json     "purchases"
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

  create_table "inventory_assets", force: :cascade do |t|
    t.string   "appid"
    t.string   "amount"
    t.string   "assetid"
    t.string   "classid"
    t.string   "contextid"
    t.string   "instanceid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["classid", "instanceid"], name: "index_inventory_descriptions_on_classid_and_instanceid", using: :btree
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
    t.json     "descriptions"
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
    t.json     "owner_actions"
    t.integer  "status"
    t.integer  "tradable"
    t.string   "type"
    t.string   "item_nameid"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.json     "actions"
    t.integer  "goo_value"
    t.integer  "market_fee_app"
    t.string   "name_color"
    t.string   "market_fee"
    t.string   "contained_item"
    t.json     "market_actions"
    t.json     "tags"
    t.json     "item_expiration"
    t.index ["classid"], name: "index_market_assets_on_classid", unique: true, using: :btree
    t.index ["item_nameid"], name: "index_market_assets_on_item_nameid", using: :btree
    t.index ["market_hash_name"], name: "index_market_assets_on_market_hash_name", using: :btree
    t.index ["type"], name: "index_market_assets_on_type", using: :btree
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
    t.index ["item_nameid"], name: "index_order_histograms_on_item_nameid", unique: true, using: :btree
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
