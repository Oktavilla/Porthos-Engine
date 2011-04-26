# This controller handles the login/logout function of the site.
class Admin::SessionsController < ApplicationController
  include Porthos::Admin
  skip_before_filter :authenticate!
  layout 'admin/sessions'

  def index
    redirect_to admin_dashboard_path
  end

  # render new.html.erb
  def new
  end

  def create
    user = warden.authenticate!
    sign_in user
    flash[:notice] = t(:'authentication.signed_in')
    redirect_to admin_root_path
  end

  def destroy
    sign_out
    flash[:notice] = t(:logged_out, :scope => [:app, :admin_general])
    redirect_to admin_login_path
  end

end
