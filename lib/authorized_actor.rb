# === AuthorizedActor : It's like <tt>User.current_user</tt>
# 
# A common practice in rails applications and in authentication plugins is to 
# have the method +current_user+ available on every controller (via ApplicationController).
# 
# It's also common practice (although slightly less common), to have that user also available 
# globally to your application through an accessor of <tt>User.current_user</tt>
# 
# So it might make sense for permission enforcement in this plugin to work by 
# calling <tt>User.current_user</tt> and assume that it will return an object on which we can 
# call <tt>permissions</tt> to get a valid permissions-defining module (one that includes DefinePermissions::Definition)
# with which we can evaluate wether or not a certain thing is allowed.
# 
# *However*, such an assumption is not always valid.  
# And it just so happens to NOT be valid for the app this plugin was originally built for.  
# So instead, the enforcement modules call <tt>AuthorizedActor.current_actor</tt>.
# Which in most apps, should nearly be the same thing as calling <tt>User.current_user</tt>.
# 
# It is expected that in your authentication code, you will appropriately make calls to 
# <tt>current_actor=</tt> for the benefit of proper enforcement.
# 
# AuthorizedActor::AnythingGoes and AuthorizedActor::Guest are provided as default 
# implementations of actor who can do Everything and Nothing (respectively).
#
# If you plan to make User your actor, here's an imagined example of what it might look like...
#
#  class User
#   include AuthorizedActor
#   
#   module AdminUserPermissions
#     include DefinePermissions::Definition
#     ....
#   end
#   
#   module NormalUserPermissions
#     include DefinePermissions::Definition
#     ...
#   end
#   
#   def permissions
#     if self.admin?
#       AdminUserPermissions
#     else
#       NormalUserPermissions
#     end
#   end
#   
#  end
#
# And here's an example pseudo-login method:
# 
#   def login(username, password)
#     user = User.find_by_username(username)
#     if user.authenticate!(password)
#        AuthorizedActor.current_actor = user
#     else
#        AuthorizedActor.current_actor = AuthorizedActor::Guest.new
#     end
#   end
#
# <b>next Chapter</b>:: ProtectedModel.
#
module AuthorizedActor  
  include DefinePermissions::Actor
  
  # Set the current actor, which enforcment modules ProctedModel, ProctedController, and ProtecFields will use to check permissions
  #
  # The actor set must include the AuthorizedActor module
  def self.current_actor=(actor)
    raise ArgumentError, "#{actor} does not implement #{AuthorizedActor}" unless actor.is_a?(AuthorizedActor)
    Thread.current['current_actor'] = actor
  end
  
  #Returns the current actor.
  def self.current_actor
    Thread.current['current_actor'] ||= Guest.new
  end
  
end

#An Actor class with permission to do anything
class AuthorizedActor::AnythingGoes
  include AuthorizedActor

  module AnythingGoesPermissions # :nodoc:
    include DefinePermissions::Definition
  end

  def permissions # :nodoc:
    AnythingGoesPermissions
  end
  
  #Override the permission undefined failure to return true (Permitted) for all permission checks
  def handle_permission_undefined(failure)
    true
  end
  
end

#An Actor class with permission to do nothing
class AuthorizedActor::Guest
  include AuthorizedActor

  module GuestPermissions # :nodoc:
    include DefinePermissions::Definition
  end

  def permissions # :nodoc:
    GuestPermissions
  end
  
  #Override the permission undefined failure to return false (Denied) for all permission checks
  def handle_permission_undefined(failure)
    false
  end

end