# == Schema Information for the samples used below
#
# Table name: marketers
#  id                             :bigint(8)        not null, primary key
#
# Table name: prospects
#  id           :bigint(8)        not null, primary key
#  marketer_id  :bigint(8)
#  email        :string
#  eo_domain_id :bigint(8)
#
# Table name: eo_drip_lists
#  id                                 :bigint(8)        not null, primary key
#  decline_unknown_emails             :boolean
#  decline_prospects_already_involved :boolean
#  brand_id                           :bigint(8)
#  decline_prospects_brandly_involved :boolean
#
# Table name: eo_campaigns
#  id                           :bigint(8)        not null, primary key
#  marketer_id                  :bigint(8)
#  brand_id                     :bigint(8)
#
# Table name: eo_progressions
#  id                                :bigint(8)        not null, primary key
#  eo_campaign_id                    :bigint(8)
#  prospect_id                       :bigint(8)
#
# Table name: eo_blacklisted_domains
#  id          :bigint(8)        not null, primary key
#  domain      :string
#  marketer_id :bigint(8)
#  brand_id    :bigint(8)
#
# Table name: eo_domains
#  id          :bigint(8)        not null, primary key
#  marketer_id :bigint(8)
#  domain      :string
#
#
#
# task:
# check if need to decline a drip_list
module Prospects
  class EoDripListsIdsScopeBuilder
    # [...]
    def need_to_decline_drip_list?(drip_list)
      same_email_prospects = @marketer.prospects.where(email: @email)

      prospect_is_involved_in_a_campaign = same_email_prospects.any?(&:involved_in_campaign?)
      prospect_is_brandly_involved = same_email_prospects.any? do |prospect|
        prospect.involved_in_brand_specific_campaign?(drip_list.brand)
      end

      decline_by_campaign_involvement =
        drip_list.decline_prospects_already_involved && prospect_is_involved_in_a_campaign
      decline_by_brand_involvement =
        drip_list.decline_prospects_brandly_involved && prospect_is_brandly_involved

      decline_by_campaign_involvement || decline_by_brand_involvement
    end
    # [...]
  end
end

class Prospect < ApplicationRecord
  def involved_in_campaign
    # check-if-involved stub
  end

  def involved_in_brand_specific_campaign?(brand)
    # check-if-involved stub
  end
end

#
# given:
# @input - text with snippets of the following format:
#  "((Hello|Hi|Greetings))"
# task:
# implement a method to substitute these snippets in the text with samples of the variations
def variate_the_input
  text_variations = @input.scan(/(?<=\(\().+?(?=\)\))/).flatten

  text_variations.each do |text_variation|
    variations = text_variation.split('|')
    @input.gsub!("((#{text_variation}))", variations.sample)
  end
end

# task:
# implement an instance method to check if given domain is blacklisted:
# the domain is in black list and has no brand
# the domain is in black list and has the same brand as the eo_campaign does
class EoProgression < ApplicationRecord
  def domain_blacklisted?
    eo_blacklisted_domain =
      eo_campaign.marketer.eo_blacklisted_domains.find_by(domain: prospect.eo_domain&.domain)
    return false unless eo_blacklisted_domain # domain is not in the black list

    # the domain is in the black list
    eo_blacklisted_domain_brand = eo_blacklisted_domain.brand
    return true unless eo_blacklisted_domain_brand  # the domain has no brand

    # check if the domain and the eo_campaign have the same brand
    eo_blacklisted_domain_brand == eo_campaign.brand
  end
end

# task:
# filter the scope using gem 'ransack'
# the filters may include 'AND' & 'OR' modifiers simultaniously
# Expected @params:
# {
#   filters: { # optional, here goes filters for ransack
#     to_dos_type_eq: 'draft',
#     created_at: 'datetime',
#     user_id_null: true,
#     user_id_eq_any: [1, 2],
#     user_id_not_eq_all: [3, 4],
#     to_dos_type_eq_any ['reply'],
#     eo_campaign_brand_id_eq_any: [1, 2],
#     eo_campaign_brand_id_not_eq_all: [3, 4],
#     eo_campaign_id_eq_any: [1, 2],
#     eo_campaign_id_not_eq_all: [3, 4]
#   }
# }
def filter_scope(scope)
  filters = @params[:filters]

  # keys of filters that need modifier `OR`
  conflicting_filters_keys = %w[user_id_eq_any user_id_null]

  modifier_or_is_required = (filters.keys & conflicting_filters_keys) == conflicting_filters_keys
  return scope.ransack(filters).result unless modifier_or_is_required

  # separate filters that need different modifiers
  user_filters = filters.extract!(*conflicting_filters_keys)

  # need to chain ransack conditions that use different modifiers
  scope.ransack(filters).result.ransack(user_filters.merge(m: 'or')).result
end
