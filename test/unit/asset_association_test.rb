require_relative '../test_helper'

class AssetAssociationTest < ActiveSupport::TestCase
  context "A asset association" do
    setup do
      Resizor.configure do |config|
        config.api_key = 'test-api-key'
      end
      WebMock.disable_net_connect!
      stub_resizor_post
      stub_s3_put
      stub_s3_head
      @asset = Factory.create(:image_asset, {
        title: 'A fine image',
        description: 'Looks good it does',
        author: 'God',
        file: new_tempfile('image')
      })
      @page = Factory.build(:page)
      @asset_association = AssetAssociation.new(:asset => @asset)
      @page.data << @asset_association
    end

    should 'dup the assets attributes when new' do
      fields_to_be_copied = %w{title description author}
      fields_to_be_copied.each do |field|
        assert_nil @asset_association[field], "Should not have a value for #{field} yet"
      end

      assert @page.save

      fields_to_be_copied.each do |field|
        assert_equal @asset[field], @asset_association[field], "Should have copied the value for #{field}"
      end
    end

    should "notify asset about it's context when created" do
      assert_equal [], @asset['_usages']
      @asset_association.save && @asset.reload
      assert @asset.usages.include?(@asset_association._root_document)
    end

    context 'when changing the asset_id' do
      setup do
        @asset_association.save
        @new_asset = Factory.create(:image_asset, {
          title: 'A finer image',
          description: 'Looks gooder it does',
          author: 'Gods',
          file: new_tempfile('image')
        })
        @asset_association.update_attributes(asset_id: @new_asset.id)
        @asset.reload
        @new_asset.reload
      end

      should 'notify the old asset' do
        refute @asset.usages.include?(@asset_association._root_document), "Old asset should no longer know about the asset_association"
      end

      should 'notify the new asset' do
        assert @new_asset.usages.include?(@asset_association._root_document), "New asset should know about the asset_association"
      end

    end

  end
end