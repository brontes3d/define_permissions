#extends protected_controller system
# require File.expand_path(File.dirname(__FILE__) + '/../protected_controller_voting_system/controllers.rb')
require File.expand_path(File.dirname(__FILE__) + '/../protected_controller_voting_system/candidates_controller.rb')

class ElectionsController < ActionController::Base
  include ProtectFields
  
  #re-raise errors up to the tests
  def rescue_action(e) raise e end
    
  def edit
    render :action => 'theview'
  end

  def show
    render :action => 'theview'
  end
  
  protected
  
  #normally, this comes from make_resourceful
  def current_model
    Election
  end

  #normally, this comes from make_resourceful
  def current_object
    Election.find(params[:id])
  end
      
end