#extends protected_model system
require File.expand_path(File.dirname(__FILE__) + '/../protected_model_voting_system/models.rb')

module CandidatePermissions
  include DefinePermissions::Definition
  
  permitted_actions_on(CandidatesController) do 
     permit(:edit) do |me, candidate|
       me.is_a?(Candidate) && (me.id == candidate.id)
     end
     permit(:show)
     deny(:all)
  end
  
  find_permissions(Candidate) do
      {}
  end
  
  permitted_fields_on(Candidate) do
    show do
      permit(:all)
    end
  end
  
end

class Candidate < ActiveRecord::Base
  include AuthorizedActor
  
  def permissions
    CandidatePermissions
  end
  
end

# module VoterPermissions
#   
#   permitted_actions_on(Voter) do 
#      permit(:show) do |me, voter|
#        me.id == voter.id
#      end
#      deny(:all)
#   end
#   
# 
# end