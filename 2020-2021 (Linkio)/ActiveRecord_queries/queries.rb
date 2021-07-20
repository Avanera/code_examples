# == Schema Information for the samples used below
#
# Table name: eo_campaigns
#  id                           :bigint(8)        not null, primary key
#  brand_id                     :bigint(8)
#
# Table name: prospects
#  id           :bigint(8)        not null, primary key
#  email        :string
#
# Table name: eo_progressions
#  id                                :bigint(8)        not null, primary key
#  eo_campaign_id                    :bigint(8)
#  prospect_id                       :bigint(8)
#  stage                             :string
#
# Table name: brands
#  id                           :bigint(8)        not null, primary key
#  name                         :string
#
# Table name: eo_messages
#  id                  :bigint(8)        not null, primary key
#  eo_campaign_id      :bigint(8)
#  parent_message_id   :bigint(8)
#  created_at          :datetime         not null
#
#
#
# task:
# implement a scope to display prospects not involved in brand specific campaign
class Prospect < ApplicationRecord
  has_many :eo_progressions, dependent: :destroy
  has_many :eo_campaigns, through: :eo_progressions

  scope :not_involved_in_brand_specific_campaign, lambda { |brand|
    already_involved_ids = joins(:eo_campaigns).where("eo_campaigns.brand_id = #{brand.id}").ids

    where.not(id: already_involved_ids)
  }
end

# task:
# return metrics in the following format:
#   [
#     { 'date' => '2020-11-17', 'emails_sent' => 5 },
#     { 'date' => '2020-11-18', 'emails_sent' => 1 },
#     { 'date' => '2020-11-19', 'emails_sent' => 2 }
#   ]
marketer = @context.marketer
start_date = @context.params[:start_date] || Date.current - 1.week
end_date = @context.params[:end_date] || Date.current
EoMessage
  .where(eo_campaign_id: marketer.eo_campaigns)
  .where('DATE(created_at) BETWEEN ? AND ? AND parent_message_id IS NULL', start_date, end_date)
  .group('created_at::date')
  .count
  .map { |k, v| { date: k, emails_sent: v } }

# task:
# return metrics in the following format:
#   {
#     'started' => 22,
#     'active' => 10,
#     'paused_or_completed' => 12
#   }
EoCampaign
  .left_outer_joins(:eo_progressions)
  .select(
    <<~SQL
      eo_campaigns.id,
      COUNT(*) FILTER (WHERE stage IS NOT NULL) AS started,
      COUNT(*) FILTER (WHERE stage = ANY ('{waiting, starting, running}')) AS active,
      COUNT(*) FILTER (WHERE stage = ANY (
        '{rejected, bounced, unsubscribed, out_of_office, replied, completed, has_error, canceled}'
      )) AS paused_or_completed
    SQL
  )
  .group(:id)
  .find(@context.params[:id])
