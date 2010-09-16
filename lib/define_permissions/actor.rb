# If you are using AuthorizedActor, this module is automatically included.
#
# If you wanted to use DefinePermissions without AuthorizedActor, 
# your actors would have to include this module.
#
# DefinePermissions::Actor defines all the permission checking methods that can be called 
# on a particular actor to determine if a given thing is permitted on denied for this actor.
#
# ProtectedModel, ProtectedController, and ProtectFields, all make use of this module's API 
# to perform their checks and access the information in the current actor's DefinePermissions::Definition module.
#
# To check permissions defined with:
#
# find_permission :: use get_find_scoping_conditions
# permitted_objects_for :: use check_permissions_for_named_thing (or permitted / check_permitted)
# permitted_actions_on :: use check_permissions_for_action_on_model (or permitted / check_permitted)
# permitted_fields_on :: use check_field_permission
# 
module DefinePermissions::Actor
        
  def handle_permission_undefined(failure)
    raise failure
  end
  
  def permission_undefined
    begin
      yield
    rescue DefinePermissions::PermissionNotDefined => failure
      handle_permission_undefined(failure)
    end
  end
  
  def get_find_scoping_conditions(on_class)
    # on_module = "#{role.to_s}_permissions".camelize.constantize
    on_module = self.permissions

    not_defined_action = Proc.new{
      if(permission_undefined{ raise DefinePermissions::PermissionNotDefined.new("no find_permissions for #{on_class} defined on #{on_module}") })
        {}
      else
        DefinePermissions::FIND_DENIED
      end
    }
    
    proc_to_call = on_module.get_find_permissions_proc(on_class) || not_defined_action
    
    proc_to_call.call(self)
  end
  
  def check_field_permission(action, on_class, on_object, for_attribute)
    # on_module = "#{role.to_s}_permissions".camelize.constantize
    # puts "checking field perms: #{action}, #{on_class}, #{on_object}, #{for_attribute}"
    
    on_module = self.permissions

    not_defined_action = Proc.new{
      permission_undefined{
          raise DefinePermissions::PermissionNotDefined.new("no permissions for #{on_class}, #{action}, #{for_attribute} defined on #{on_module}")}
    }

    proc_to_call = on_module.get_permitted_fields_proc(on_class, action.to_sym, for_attribute.to_sym) || not_defined_action
    
    proc_to_call.call(self, on_object)
  end
    
  def permitted(to_do_thing, on_object = nil)
    check_permissions_for_named_thing(to_do_thing, on_object)
  end
  
  def check_permissions_for_named_thing(check_permission_to, on_object = nil)
    on_module = self.permissions
    
    not_defined_action = Proc.new{
      permission_undefined{
          raise DefinePermissions::PermissionNotDefined.new("no permissions for thing #{check_permission_to} defined on #{on_module}")}
    }

    proc_to_call = on_module.get_permitted_object_proc(check_permission_to.to_sym) || not_defined_action
    
    #TODO: we don't have any tests that are actually passing an object for this... perhaps we should remove the support for things we don't test (And aren't using)
    proc_to_call.call(self, on_object)
  end
  
  def action_permitted?(check_permission_to, on_class, on_object = nil)
    check_permissions_for_action_on_model(check_permission_to, on_class, on_object)
  end
  
  def check_permissions_for_action_on_model(check_permission_to, on_class, on_object = nil)
    on_module = self.permissions
    
    # puts "check_permissions_for_action_on_model #{check_permission_to}, #{on_module}, #{on_class}"
    not_defined_action = Proc.new{
      permission_undefined{
          raise DefinePermissions::PermissionNotDefined.new("no permissions for action #{check_permission_to} on #{on_class} defined on #{on_module}")}
    }
    
    # puts "perm to #{check_permission_to} on #{on_class} on #{on_object}"
    # puts "running on #{on_module}"
    proc_to_call = on_module.get_permitted_action_proc(on_class, check_permission_to.to_sym) || not_defined_action
    # puts "proc_to_call #{proc_to_call}"
    
    #If on_object is a Proc then don't evaluate unless the permission check actually accepts those arguments
    #This prevents evaluation of current_object in situations where it's not relevant, so long as the permssion check isn't asking for that argument
    if on_object.is_a?(Proc)
      if proc_to_call.arity >= 2
        proc_to_call.call(self, on_object.call)
      else
        proc_to_call.call(self)
      end
    else
      proc_to_call.call(self, on_object)
    end
  end
    
end