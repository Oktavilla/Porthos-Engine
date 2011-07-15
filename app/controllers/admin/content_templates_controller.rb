class Admin::ContentTemplatesController < ApplicationController
  respond_to :html
  include Porthos::Admin

  def index
    @content_templates = ContentTemplate.sort(:position).all
    respond_with(@content_templates)
  end

  def show
    @content_template = ContentTemplate.find(params[:id])
    respond_with(@content_template)
  end

  def new
    @content_template = ContentTemplate.new
  end

  def create
    @content_template = ContentTemplate.new(params[:content_template])
    if @content_template.save
      flash[:notice] = "#{@content_template.label}  #{t(:saved, :scope => [:app, :admin_general])}"
    end
    respond_with(@content_template, :location => admin_content_template_path(@content_template.id))
  end

  def edit
    @content_template = ContentTemplate.find(params[:id])
  end

  def update
    @content_template = ContentTemplate.find(params[:id])
    if @content_template.update_attributes(params[:content_template])
      flash[:notice] = "#{@content_template.label}  #{t(:updated, :scope => [:app, :admin_general])}"
    end
    respond_with(@content_template, :location => admin_content_template_path(@content_template))
  end

  def destroy
    @content_template = ContentTemplate.find(params[:id])
    if @content_template.destroy
      flash[:notice] = "#{@content_template.label}  #{t(:deleted, :scope => [:app, :admin_general])}"
    end
    redirect_to admin_content_templates_path
  end

  def sort
    params[:content_template].each_with_index do |id, i|
      ContentTemplate.set(id, :position => i+1)
    end if params[:content_template]
    respond_to do |format|
      format.js { render :nothing => true }
    end
  end

end