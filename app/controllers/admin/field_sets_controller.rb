class Admin::FieldSetsController < ApplicationController
  include Porthos::Admin
  before_filter :login_required

  def index
    @field_sets = FieldSet.all(:order => 'position')
    respond_to do |format|
      format.html
    end
  end

  def show
    @field_set = FieldSet.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @field_set = FieldSet.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @field_set = FieldSet.new(params[:field_set])
    respond_to do |format|
      if @field_set.save
        format.html { redirect_to admin_field_set_path(@field_set) }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @field_set = FieldSet.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @field_set = FieldSet.find(params[:id])
    respond_to do |format|
      if @field_set.update_attributes(params[:field_set])
        format.html { redirect_to admin_field_set_path(@field_set) }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @field_set = FieldSet.find(params[:id])
    @field_set.destroy
    respond_to do |format|
      format.html { redirect_to admin_fields_path }
    end
  end

  def sort
    params[:field_sets].each_with_index do |id, index|
      FieldSet.update(id, :position => index + 1)
    end
    respond_to do |format|
      format.js { render :nothing => true }
    end
  end
  
  def pages
    @field_set = FieldSet.find(params[:id])
    @pages = @field_set.pages.all(:order => 'position')
    respond_to do |format|
      format.html
    end
  end
end