require_relative '../../test_helper'
class PageTemplatesTest < ActiveSupport::IntegrationCase

  setup do
    login!
  end

  test 'listing page_templates' do
    page_template = FactoryGirl.create(:page_template)

    visit admin_page_templates_path
    assert page.find("#page_templates #page_template_#{page_template.id}").has_content?(page_template.label), 'Page template should be in the list'
  end

  test 'creating a page template' do
    visit admin_page_templates_path

    click_link I18n.t(:'admin.page_templates.index.new')

    assert_equal new_admin_page_template_path, current_path

    fill_in 'page_template_label', :with => 'Article'
    fill_in 'page_template_page_label', :with => 'Title'
    fill_in 'page_template_instruction_body', :with => 'Be smart about the title'
    fill_in 'page_template_handle', :with => 'article'
    check 'page_template_allow_node_placements'
    check 'page_template_allow_categories'
    select Page.human_attribute_name(:published_on), from: 'page_template_sortable_field'
    select 'desc', from: 'page_template_sortable_operator'
    click_button I18n.t(:save)

    assert has_flash_message?('Article'), 'Should have a flash notice about the new page template'
    assert page.find("#content .notice").has_content?(I18n.t(:'admin.page_templates.show.blank_slate')), 'Should display blank slate message'
  end

  test 'editing a page template' do
    page_template = FactoryGirl.create(:page_template)
    visit admin_page_templates_path

    within("#page_templates #page_template_#{page_template.id}") do
      click_link page_template.label
    end

    within(".header") do
      click_link I18n.t(:'admin.page_templates.show.edit')
    end

    fill_in 'page_template_label', :with => 'New awesome title'
    click_button I18n.t(:save)

    assert has_flash_message?('New awesome title'), 'Should have a flash notice with the new title'
  end

  test "destroying a page template" do
    page_template = FactoryGirl.create(:page_template)
    visit admin_page_template_path(page_template)

    within(".header") do
      click_link I18n.t(:'admin.page_templates.show.destroy')
    end

    assert_equal admin_page_templates_path, current_path
    assert has_flash_message?(page_template.label), 'Should have a flash notice with the new title'
    refute page.has_css?("#page_templates #page_template_#{page_template.id}"), 'page template removed'
  end

end