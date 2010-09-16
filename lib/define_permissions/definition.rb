# Include this module in your permission-defining modules
# 
# Defines both the API for defining a particular set of permissions/constraints, 
# and the API for retrieving those permissions/constraints
#
#
# Permission definition should make use of the following methods:
# fallback_on :: name a module which should be checked for a permission if it is not defined in this module
# find_permissions :: define the scope with which a particular model should be searched (scoping ActiveRecord finds)
# permitted_actions_on :: define allowed/denied controller actions
# permitted_fields_on :: define the set of fields permitted to be shown, updated, or created, on a particular model
# permitted_objects_for :: define a value for a key, to be checked manually by calling DefinePermissions::Actor.permitted
#
# definitions aren't enforced unless ProtectedModel, ProtectedController, and ProtectFields 
# are included in the proper models/controllers
# 
module DefinePermissions::Definition
  
  #implementation details of DefinePermissions::Definition.permitted_actions_on
  class ActionPermissionCollector # :nodoc:
    PERMIT_PROC = Proc.new{ true }
    DENY_PROC = Proc.new{ false }
    def initialize(proc_collection)
      @proc_collection = proc_collection
    end
    def permit(*args, &block)
      args.each do |arg|
        if arg.is_a?(Regexp) && @proc_collection.respond_to?(:regex)
          if block_given?
            @proc_collection.regex(arg, block)
          else
            @proc_collection.regex(arg, PERMIT_PROC)
          end
        else
          if block_given?
            @proc_collection[arg.to_sym] = block
          else
            @proc_collection[arg.to_sym] = PERMIT_PROC
          end
        end
      end
    end
    def deny(*args)
      args.each do |arg|
        if arg.is_a?(Regexp) && @proc_collection.respond_to?(:regex)
          @proc_collection.regex(arg, DENY_PROC)
        else
          @proc_collection[arg.to_sym] = DENY_PROC
        end
      end
    end
  end
  
  class ExtendedHash < Hash
    def find_match(for_attribute)
      (@regexes || []).each do |expr, block|
        if expr.match(for_attribute.to_s)
          return block
        end
      end
      return false
    end
    def regex(expr, block)
      @regexes ||= []
      @regexes << [expr, block]
    end
  end
  
  #implementation details of DefinePermissions::Definition.permitted_fields_on
  class FieldPermissionCollector # :nodoc:
    def initialize(proc_collection)
      @proc_collection = proc_collection
    end
    def show(&block)
      for_action(:show, &block)
    end
    def create(&block)
      for_action(:create, &block)
    end
    def update(&block)
      for_action(:update, &block)
    end
    def for_action(action, &block)
      @proc_collection[action] ||= ExtendedHash.new
      ActionPermissionCollector.new(@proc_collection[action]).instance_eval(&block)      
    end
  end
  
  #The usual Module.included... adds a bunch of methods to the permission defining module
  def self.included(base) # :nodoc:
    
    base.class_eval do
      mattr_accessor :permitted_object_procs
      mattr_accessor :permitted_action_procs
      mattr_accessor :permitted_fields_procs
      mattr_accessor :find_permissions_procs
      
      def self.fallback_on_modules
        @fallback_on_modules ||= []
      end
      def self.detect_fallback(&block)
        if fallback = fallback_on_modules.detect { |f| block.call(f) }
          block.call(fallback)
        end
      end
      
      # Set a key value pair which can be later checked with DefinePermissions::Actor.permitted
      # 
      # In the argument, set the name to be used for retrieval of this permission. 
      # In the block, setup the value to return.
      #
      # Example (definition):
      #   permitted_objects_for(:primary_navigation) do
      #     ['dashboard', 'users']
      #   end
      #   
      # Example (retrieval):
      #   <% AuthorizedActor.current_actor.permitted(:primary_navigation).each do |x| -%>
      #     <%= link_to x.titleize, {:controller => x} %>
      #   <% end -%>
      #   
      def self.permitted_objects_for(named, &block) # :yields: current_actor
        permitted_object_procs[named] = block
      end
      # API for DefinePermissions::Actor to retrive things set by permitted_objects_for
      def self.get_permitted_object_proc(check_permission_to)
        permitted_object_procs[check_permission_to] || detect_fallback do |fallback|
          fallback.get_permitted_object_proc(check_permission_to)
        end
      end
      
      # Specify the actions to 'permit' and 'deny'.
      # You can specify a particular actions (like <tt>permit(:show)</tt>)
      # Or specify all to affect any actions that weren't name specifically (like <tt>deny(:all)</tt>)
      #
      # Example (definition):
      #    permitted_actions_on(ElectionController) do 
      #       permit(:vote)
      #       permit(:edit) { |me, election_to_act_on|
      #         me.elections_i_own.include?( election_to_act_on )
      #       }
      #       deny(:all)
      #    end
      # 
      # The above example defines the following permissions:
      # * permitted to run the 'vote' action on ElectionController
      # * permitted to run the 'edit' action on ElectionController, but only if that Election is associated with current_actor via 'elections_i_own'
      # * denied to run any other actions on ElectionController
      #   
      def self.permitted_actions_on(*args, &block)
        args.each do |klass|      
          permitted_action_procs[klass] ||= {}
          ActionPermissionCollector.new(permitted_action_procs[klass]).instance_eval(&block)
        end
      end
      # API for DefinePermissions::Actor to retrive things set by permitted_actions_on
      def self.get_permitted_action_proc(on_class, check_permission_to)
        (permitted_action_procs[on_class] && 
          (permitted_action_procs[on_class][check_permission_to] || 
          permitted_action_procs[on_class][:all])) || detect_fallback do |fallback|
               fallback.get_permitted_action_proc(on_class, check_permission_to)
             end
      end
      
      def self.permitted_fields_on(*args, &block)
        args.each do |klass|      
          permitted_fields_procs[klass] ||= {}
          FieldPermissionCollector.new(permitted_fields_procs[klass]).instance_eval(&block)
        end
      end
      def self.get_permitted_fields_proc(on_class, for_action, for_attribute)
        ((permitted_fields_procs[on_class] && permitted_fields_procs[on_class][for_action]) && 
            (permitted_fields_procs[on_class][for_action][for_attribute] ||
             permitted_fields_procs[on_class][for_action].find_match(for_attribute) ||
             permitted_fields_procs[on_class][for_action][:all])) || detect_fallback do |fallback|
               fallback.get_permitted_fields_proc(on_class, for_action, for_attribute)
             end
      end
      
      
      def self.find_permissions(*args, &block)
        args.each do |klass|
          find_permissions_procs[klass] ||= block
        end
      end
      def self.get_find_permissions_proc(on_class)
        find_permissions_procs[on_class] || detect_fallback do |fallback|
           fallback.get_find_permissions_proc(on_class)
         end
      end
      
      def self.fallback_on(*modules_to_fallback_on)
        @fallback_on_modules = modules_to_fallback_on
      end
      
    end
    base.permitted_action_procs = {}
    base.permitted_object_procs = {}
    base.permitted_fields_procs = {}
    base.find_permissions_procs = {}
    # base.this_module = base    
  end
  
end