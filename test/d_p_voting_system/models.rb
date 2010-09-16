class Election < ActiveRecord::Base
end
class SomethingOnlyInDefault
end
class SomethingInPrimaryFallback
end
class SomethingNowhere
end
class Candidate < ActiveRecord::Base
end
class Voter < ActiveRecord::Base
end

module DefaultPermissions
  include DefinePermissions::Definition
  
  permitted_actions_on(SomethingOnlyInDefault) do 
     permit(:something)
     deny(:something_else)
  end
  
  permitted_fields_on(SomethingOnlyInDefault) do
    create { permit(:all) }
    update { permit(:all) }
    show { permit(:all) }
  end
  
  find_permissions(SomethingOnlyInDefault) do
    {}
  end
  
end

module PrimaryFallback
  include DefinePermissions::Definition
  
  permitted_actions_on(SomethingInPrimaryFallback) do 
     permit(:thing)
  end
  
  permitted_objects_for(:thing_in_fallback) do
    ['thing']
  end
  
  permitted_fields_on(SomethingInPrimaryFallback) do
    create { permit(:all) }
    update { permit(:all) }
    show { permit(:all) }
  end
  
  find_permissions(SomethingInPrimaryFallback) do
    {}
  end
   
end

module VoterPermissions
  include DefinePermissions::Definition
  
  fallback_on PrimaryFallback, DefaultPermissions
  
  find_permissions(Election) do
      {}
  end
  
  permitted_objects_for(:political_parties) do
    ['democrat', "republican", "independent"]
  end

  find_permissions(Voter) do |me|
    {:conditions => ["id = ?", me.id]}
  end
  
  permitted_actions_on(Election) do 
     permit(:vote)
     permit(:belong_in) { |me, election_to_act_on|
       me.election == election_to_act_on
     }
     deny(:all)
  end
  
  #it is assumed that you will never ACTUALLy update the id column of an entity, 
  #so giving permission to create or update id means, basic create / update  
  permitted_fields_on(Voter) do
    create do
      deny(:all)
    end
    update do
      permit(:all) do |me, voter_to_act_on|
        me == voter_to_act_on
      end
    end
    show do
      permit(:name, :id)
      deny(:all)
    end
  end
    
end

class Voter < ActiveRecord::Base 
  belongs_to :election
  
  include DefinePermissions::Actor
  
  def permissions
    VoterPermissions
  end
  
end
