class Admin::DisplayOptionsController < ApplicationController
  respond_to :html
  include Porthos::Admin

  def index
    @display_options = DisplayOption.all
  end

  def new
    @display_option = DisplayOption.new
  end

  def create
    @display_option = DisplayOption.create params[:display_option]

    respond_with @display_option, location: admin_display_options_path
  end

  def edit
    @display_option = DisplayOption.find params[:id]
  end

  def update
    @display_option = DisplayOption.find params[:id]
    @display_option.update_attributes params[:display_option]

    respond_with @display_option, location: admin_display_options_path
  end

  def destroy
    @display_option = DisplayOption.find params[:id]
    @display_option.destroy

    respond_with @display_option, location: admin_display_options_path
  end
end
