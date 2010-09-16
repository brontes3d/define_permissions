#extends protected_controller system
require File.expand_path(File.dirname(__FILE__) + '/../protected_controller_voting_system/models.rb')

module VoterPermissions
  permitted_fields_on(Election) do
    update do
      permit(:exit_polls)
      deny(/vote.*/)
    end
    show do
      permit(:all)
    end
  end

end

module CandidatePermissions  
  # permitted_actions_on(Candidate) do 
  #    permit(:edit) do |me, candidate|
  #      me.is_a?(Candidate) && (me.id == candidate.id)
  #    end
  #    permit(:show)
  #    deny(:all)
  # end
  # 
  # find_permissions(Candidate) do
  #     {}
  # end
  # 
  permitted_fields_on(Election) do
    update do
      permit(:vote_tally)
      deny(:exit_polls)
    end
    show do
      permit(:vote_tally)
      deny(:exit_polls)
    end
  end
  
end