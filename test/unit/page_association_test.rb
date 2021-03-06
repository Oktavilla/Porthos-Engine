require_relative '../test_helper'
class PageAssociationTest < ActiveSupport::TestCase

  test "gets all pages except it's root as targets" do
    pages = []
    2.times do
      pages << FactoryGirl.create(:page, :published_on => 1.day.ago)
    end

    page = pages.first
    page_association = PageAssociation.new
    page.data << page_association

    assert_equal 1, page_association.targets.size
    refute page_association.targets.include?(page)
  end

  test 'gets all pages except the root and siblings as targets when child to a content block' do
    pages = []
    4.times do
      pages << FactoryGirl.create(:page, :published_on => 1.day.ago)
    end

    datum_collection = FactoryGirl.create(:datum_collection)
    pages[0].data << datum_collection
    page_association = PageAssociation.new(:page_id => pages[1].id)
    datum_collection.data << page_association
    datum_collection.data << PageAssociation.new(:page_id => pages[2].id)

    assert_equal 2, page_association.targets.size
    assert_equal [pages[1], pages[3]].sort_by { |p| p.id.to_s }, page_association.targets.sort_by { |p| p.id.to_s }
  end

  test 'targets gets scoped by page template ids' do
    published_date = 1.day.ago
    page_template = FactoryGirl.create(:page_template, :datum_templates => [])
    page1 = Page.create_from_template(page_template, :title => 'Page 1', :published_on => published_date)
    page2 = Page.create_from_template(FactoryGirl.create(:page_template), :title => 'Page 2', :published_on => published_date)
    page3 = Page.create_from_template(FactoryGirl.create(:page_template), :title => 'Page 3', :published_on => published_date)

    page2.data << PageAssociation.new(:page_template_ids => [page_template.id], :handle => 'le_page')

    assert_equal [page1], page2.data['le_page'].targets.all
  end

  test 'targets should not include unpublished pages' do
    page1 = FactoryGirl.create(:page)
    page2 = FactoryGirl.create(:page, :published_on => nil)

    page1.data << PageAssociation.new(:handle => 'le_page')

    assert_equal [], page1.data['le_page'].targets.all
  end

end