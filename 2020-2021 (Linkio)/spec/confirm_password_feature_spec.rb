require 'capybara_helper'

RSpec.describe 'Confirm password popup', type: :feature do
  let(:cuser) { create(:user) }
  let(:cmarketer) { cuser.marketers.first }
  let(:brand) do
    create(
      :brand,
      :with_se_settings,
      name: 'First Brand',
      website: 'http://example.com',
      marketer: cmarketer
    )
  end

  context 'when user updates a brand', js: true do
    it 'can be signed in with confirm-password-popup' do
      # prepare data
      brand # create brand
      cuser.add_role(:brands_admin, cmarketer)
      create(:plus_subscription, marketer: cmarketer)

      # simulate 'session expired' use-case
      bullet_proof_sign_in(cuser)
      visit edit_brand_path(brand.id)
      sign_out(cuser) # log out programmatically
      wait_for_ajax

      # an attempt to continue App usage
      within('.brand__form') do
        find('input[name="brandName"]').set('Updated Brand')
        find('input[name="website"]').set('http://updated-example.com')
        click_button('Save')
      end
      wait_for_ajax

      # system requests sign in
      expect_to_see 'PASSWORD IS REQUIRED'

      # sign in
      fill_in 'password', with: cuser.password
      click_button('Continue')

      # ensure user can continue app usage
      expect(page).to have_current_path(edit_brand_path(brand.id))
      within('.brand__form') do
        click_button('Save')
      end
      wait_for_ajax
      expect(page).to have_current_path(root_path)
      expect(brand.reload.name).to eq('Updated Brand')
      expect_to_see 'Updated Brand'
    end
  end
end
