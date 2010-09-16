# === Enforcer: ProtectedController
# 
# Include this module in your controller to enable enforcement of permitted_actions_on.
# 
# Example:
#   module VoterPermissions
#     include DefinePermissions::Definition
#     
#     permitted_actions_on(ElectionsController) do 
#        permit(:vote)
#        deny(:all)
#     end
#   end
# 
# This example permission definition implies the following rules 
# (which ProtectedController will enforce at the controller level):
# * Voters cannot perform any actions on the ElectionsController except to 'vote'
# 
# ProtectedController performs this check by adding a before_filter called check_permissions.  
# If this check fails, a SecurityError is raised. It is suggested that you make use of 
# Rails +rescue_from+ to handle such errors appropriately.  
#
# Example:
#   rescue_from SecurityError do |ex|
#     render :text => ex.message, :status => :forbidden
#   end
#
# <b>next Chapter</b>:: ProtectFields.
#
module ProtectedController
  
  def self.included(base)
    base.class_eval do
      before_filter :check_permissions
    end
  end
  
  def check_permissions
    obj = Proc.new do
      if self.respond_to?(:current_object)
        current_object
      end
    end
        
    # puts "\nAuthorizedActor.current_actor.check_permissions_for_action_on_model(action_name, self.class, obj) = #{AuthorizedActor.current_actor.check_permissions_for_action_on_model(action_name, self.class, obj).inspect}"
    # puts "self.class = #{self.class.inspect}"
    # puts "action_name = #{action_name.inspect}"
    # puts "AuthorizedActor.current_actor = #{AuthorizedActor.current_actor.inspect}"
    # puts "obj = #{obj.inspect}"
    
    if self.class.action_methods.include?(action_name) and !AuthorizedActor.current_actor.check_permissions_for_action_on_model(action_name, self.class, obj)
    # unless AuthorizedActor.current_actor.check_permissions_for_action_on_model(action_name, self.class, obj)
      logger.debug { "permissions denied for '#{action_name}' on '#{obj}'" } if logger
      raise SecurityError.new("Permission denied on the controller action '#{self.class}##{action_name}' for '#{AuthorizedActor.current_actor}'")
    end
  end
  
end