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

ActiveRecord::Schema.define(version: 20170222090855) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.integer  "item_nameid"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["classid"], name: "index_market_assets_on_classid", unique: true, using: :btree
    t.index ["item_nameid"], name: "index_market_assets_on_item_nameid", using: :btree
  end

end
