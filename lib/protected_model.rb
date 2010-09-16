# === Enforcer: ProtectedModel
# 
# ProtectedModel is a module you can include in your ActiveRecord models to enable enforcement 
# of +find_permissions+ and +permitted_fields_on+ at the model level. (see DefinePermissions::Definition)
#   
# Example for find_permissions
#   module VoterPermissions
#     include DefinePermissions::Definition
#   
#     find_permissions(Voter) do |me|
#        {:conditions => ["id = ?", me.id]}
#     end
#   end
#   
# This example permission definition implies the following rule: voters searching for other 
# voters should find only themselves.  In order for this rule to be implied, the following things must be true:
# * AuthorizedActor.current_actor must respond to the method +permissions+
# * The call to current_actor.permissions must return the module defined in this example
# * The Voter class must call <tt>include ProtectedModel</tt>
# 
# Example for permitted_fields_on
# 
#   module VoterPermissions
#     include DefinePermissions::Definition
#   
#     permitted_fields_on(Voter) do
#       create do
#         deny(:all)
#       end
#       update do
#         permit(:all) do |me, voter_to_act_on|
#           me == voter_to_act_on
#         end
#       end
#       show do
#         permit(:name, :id)
#         deny(:all)
#       end
#     end
#   end
#   
# This example permission definition implies the following rules 
# (which ProtectedModel will enforce on the model level):
# * Voters cannot create other voters
# * Voters can update any attribute on themselves
# * Voter can find other voters, and look at only their names
# 
# Notice the small overlap with the +find_permissions+ ?  When a find is run on a ProtectedModel, 
# not only are the find_permissions applied to scope the find, 
# but then after the find returns the fields +show+ permissions are applied to each entity.  
# The current_actor must have permission to show that entities :id, or permission is denied 
# and a SecurityError is raised about the permissions inconsistency.
# 
# This example also shows +create+ and +update+ permission, which ProtectedModel will enforce 
# with a before_save filter.  By using the ActiveRecord method +changed+ (new in Rails 2.1), 
# ProtectedModel can check each changed field and make an appropriate call to see if that column 
# is permitted or denied for the current actor.  If any change is denied, a SecurityError is raised.
# 
# Note that the :id column has 'special' meaning.  
# It does not mean permission to update a record's :id (you should never update an :id), 
# instead it means permission at the most basic level to do the action at all.  
# For example, if I my create permission of permit(:id) and deny(:all), 
# I would be allowed to create the entity but not set any fields on it 
# (other than those that are set automatically such as created_at and updated_at).
# 
# <b>next Chapter</b>:: ProtectedController.
#
module ProtectedModel
  KEY = "ProtectedModel.model_proctection_on"
  
  def self.ignore_permissions_while
    prev_value = Thread.current[KEY]
    Thread.current[KEY] = false
    # puts "turning off model protection"
    yield
  ensure
    # puts "turning model protection back to #{prev_value}"
    Thread.current[KEY] = prev_value
  end
  
  def self.model_proctection_on?
    unless Thread.current.key?(KEY)
      Thread.current[KEY] = true
    end
    Thread.current[KEY]
  end
  
  def self.included(base)
    base.class_eval do
      class << self
        [:find_every, :find_from_ids, :calculate].each do |find_method|
            define_method(find_method) do |*args|
              # puts "need to scope the find of: " + args.inspect + " on #{self} " + ProtectedModel.model_proctection_on?.inspect                
              return super unless ProtectedModel.model_proctection_on?
              
              find_scoping_conds = AuthorizedActor.current_actor.get_find_scoping_conditions(self) || {}
              
              check_perms_proc = Proc.new do |on_thing|
                unless !on_thing.is_a?(ActiveRecord::Base) or AuthorizedActor.current_actor.check_field_permission(:show, on_thing.class, on_thing, :id)
                  raise SecurityError.new("Permissions Inconsistency! permission denied to show #{on_thing.class}, id: #{on_thing.id} (was returned from find: #{args.inspect})")
                end
              end
              
              # Rails.logger.debug { "#{AuthorizedActor.current_actor} #{self} find scoping conds: " + find_scoping_conds.inspect }
              
              with_scope(:find => find_scoping_conds) do
                if to_return = super
                  if(to_return.is_a?(Array))
                    to_return.each do |r|
                      check_perms_proc.call(r)
                    end
                  elsif(find_method != :calculate)
                    check_perms_proc.call(to_return)
                  end
                end
                # puts "found #{to_return}"
                to_return
              end
            end
        end
      end
      
      before_save :check_permissions_for_changed_fields
      
    end
  end
  
  def check_permissions_for_changed_fields
    return unless ProtectedModel.model_proctection_on?    
    # puts "should check perms for: " + self.changes.inspect
    
    on_action = (self.new_record?)? :create : :update
    if(on_action == :create)
      assert_field_change_permitted!(:id, on_action)
    end
    self.changed.each do |attr_name|
      assert_field_change_permitted!(attr_name, on_action)
    end
  end
  
  def assert_field_change_permitted!(attr_name, on_action = :update)
    unless AuthorizedActor.current_actor.check_field_permission(on_action, self.class, self, attr_name)
      raise SecurityError.new("#{AuthorizedActor.current_actor} permission denied on: #{on_action}, #{self.class}, #{attr_name} ")            
    end
  end
  
end