require 'rails_helper'

RSpec.describe BrandPageMetrics::Builder, type: :service do
  let(:marketer) { create :marketer }
  let(:brand) { create :brand, marketer: marketer }
  let(:keyword1) { create(:keyword, brand: brand, in_tracker: true, dfs_search_volume_global: 10) }
  let(:keyword2) { create(:keyword, brand: brand, in_tracker: true, dfs_search_volume_global: 30) }
  let(:brand_page) { create(:brand_page, keywords: [keyword1, keyword2]) }

  describe '#call' do
    def method_call(brand_page)
      described_class.new(brand_page).call
    end

    def create_keyword_rank(current_keyword, value, date)
      create(
        :keyword_rank,
        keyword: current_keyword, brand_page: brand_page,
        value: value, datetime: date
      )
    end

    def create_ranks_for_today(keyword1_values:, keyword2_values:)
      keyword1_values.each { |value| create_keyword_rank(keyword1, value, Time.current) }
      keyword2_values.each { |value| create_keyword_rank(keyword2, value, Time.current) }
    end

    def create_ranks_for_yesterday(keyword1_values:, keyword2_values:)
      keyword1_values.each { |value| create_keyword_rank(keyword1, value, Date.yesterday) }
      keyword2_values.each { |value| create_keyword_rank(keyword2, value, Date.yesterday) }
    end

    it 'calculates all brand page metrics for paid accounts' do
      create_ranks_for_today(keyword1_values: [5, 2], keyword2_values: [30, 28])
      create_ranks_for_yesterday(keyword1_values: [32, 30], keyword2_values: [20, 18])
      average_of_the_smallest_ranks_today = (2 + 28) / 2

      expect(method_call(brand_page)).to eq(
        average_keywords_rank: average_of_the_smallest_ranks_today
      )
    end
  end
end
