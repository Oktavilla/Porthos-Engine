class Admin::AssetUsagesController < ApplicationController
  include Porthos::Admin
  before_filter :login_required
  skip_after_filter :remember_uri, :only => [:create, :update, :destroy]

  def new
    @asset_usage = AssetUsage.new(params[:asset_usage])
    respond_to do |format|
      format.html
    end
  end

  def create
    @asset_usage = AssetUsage.create(params[:asset_usage])
    respond_to do |format|
      format.html { redirect_to params[:return_to] || eval("admin_#{@asset_usage.parent_type.tableize}_path") }
    end
  end

  def edit
    @asset_usage = AssetUsage.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @asset_usage = AssetUsage.find(params[:id])
    respond_to do |format|
      if @asset_usage.update_attributes(params[:asset_usage])
        format.html { redirect_to params[:return_to] || eval("admin_#{@asset_usage.parent_type.tableize}_path") }
      else
        format.html { render :action => 'edit' }
      end
    end
    
  end
  
  def destroy
    @asset_usage = AssetUsage.find(params[:id])
    @asset_usage.destroy
    respond_to do |format|
      format.html { redirect_to params[:return_to] || eval("admin_#{@asset_usage.parent_type.tableize}_path") }
    end
  end
  
  def sort
    params[:asset_usages].each_with_index do |id, idx|
      AssetUsage.update(id, :position => idx+1)
    end
    respond_to do |format|
      format.js { render :nothing => true }
    end
  end
end