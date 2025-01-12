# encoding: UTF-8
# frozen_string_literal: true

class OtcOrderBid < OtcOrder
  has_many :otc_trades, foreign_key: :bid_id
  # zealousWang todo : need to check and update for OTC
  scope :matching_rule, -> {otc_order(price: :desc, created_at: :asc)}

  validates :price,
            numericality: {less_than_or_equal_to: ->(otc_order) {otc_order.otc_market.max_bid}},
            if: ->(otc_order) {otc_order.otc_market.max_bid.present?}

  validates :origin_volume,
            presence: true,
            numericality: {greater_than_or_equal_to: ->(otc_order) {otc_order.otc_market.min_bid_amount}},
            if: ->(otc_order) {otc_order.otc_market.min_bid_amount.present?}

  def hold_account
    member.get_account(bid)
  end

  def hold_account!
    Account.lock.find_by!(member_id: member_id, currency_id: bid)
  end

  def expect_account
    member.get_account(ask)
  end

  def expect_account!
    Account.lock.find_by!(member_id: member_id, currency_id: ask)
  end

  def avg_price
    return ::OtcTrade::ZERO if funds_received.zero?
    config.fix_number_precision(:bid, funds_used / funds_received)
  end

  LOCKING_BUFFER_FACTOR = '1.1'.to_d

  def compute_locked
    price * volume
  end

end

# == Schema Information
# Schema version: 20190611134619
#
# Table name: otc_orders
#
#  id             :integer          not null, primary key
#  bid            :string(10)       not null
#  ask            :string(10)       not null
#  otc_market_id  :string(20)       not null
#  member_id      :integer          not null
#  offer_id       :integer
#  msg            :string(255)
#  price          :decimal(32, 16)
#  volume         :decimal(32, 16)  not null
#  origin_volume  :decimal(32, 16)  not null
#  fee            :decimal(32, 16)  default(0.0), not null
#  state          :integer          not null
#  type           :string(12)       not null
#  locked         :decimal(32, 16)  default(0.0), not null
#  origin_locked  :decimal(32, 16)  default(0.0), not null
#  funds_received :decimal(32, 16)  default(0.0)
#  trades_count   :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_otc_orders_on_offer_id  (offer_id)
#
