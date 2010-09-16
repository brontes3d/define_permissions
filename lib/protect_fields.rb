# === Enforcer: ProtectFields
# 
# Include this module in your controller to enable view level protection of <tt><% field(...){ ... } %> </tt> calls. (from FieldHelper plugin)
# 
# Example
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
# This example permission definition implies the following rules (which ProtectFields will help enforce on the view):
# * Voters cannot create other voters
# * Voters can update any attribute, but only on themselves
# * Voter can look at other voters, but see only their names
# 
# That's the very same +permitted_fields_on+ definition we used to explain ProtectedModel.  
# At the view level, we can use this definition to decide whether to show a text_field, 
# or simply display the value of, or to hide completely, a given field.
# 
# FieldHelper.field has 3 view modes +edit_as+, +show_as+ and +hide_as+. 
# ProtectFields hooks into FieldHelper to set the view mode appropriately for each field call.
# 
# Example:
#   <% field(:name){
#     edit_as(text_field(:voter, :name))
#     show_as(@voter.name)
#     hide_as{
#       %>you are not allowed to see this voter's name<%
#     }
#   } %>
# 
# If a particular actor should be allowed to edit some fields, but not all fields on a particular entity, 
# you can wrap those text_field, etc.. calls in +field+ and specify alternate content based on permissions.
#
module ProtectFields

  def actions_that_count_as_show
    ['show']
  end

  def determine_field_show_edit_or_deny(action_name, field_name)
    # puts "running on: #{action_name} and #{field_name} -- " + AuthorizedActor.current_actor.inspect

    on_thing = current_object
    #TODO: ??- rescue ActiveRecord::RecordNotFound => e 
    #TODO: raise some sort of exception with on_thing is nil... because you should never be using field() when current_object is nil    
    #RAILS_DEFAULT_LOGGER.debug("checking on thing: " + action_name.to_s + "---" + on_thing.inspect)

    if(actions_that_count_as_show.include?(action_name.to_s))
      :show if(AuthorizedActor.current_actor.check_field_permission(:show, current_model, on_thing, field_name))
    else
      if(action_name.to_s == "create" || action_name.to_s == "new")
        if AuthorizedActor.current_actor.check_field_permission(:create, current_model, on_thing, field_name)
          return :edit
        end
      elsif AuthorizedActor.current_actor.check_field_permission(:update, current_model, on_thing, field_name)
        return :edit
      end
      if(AuthorizedActor.current_actor.check_field_permission(:show, current_model, on_thing, field_name))
        return :show
      end
    end
  end

end