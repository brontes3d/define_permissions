#extends a_a_voting system
require File.expand_path(File.dirname(__FILE__) + '/../a_a_voting_system/models.rb')

module VoterPermissions
  
  #Notice, inconsistent permissions here:  the scoping provided can find candidates that are denied show of :id
  find_permissions(Candidate) do
      {}
  end  
  permitted_fields_on(Candidate) do
    show do
      deny(:all)
    end
  end
  
end

class Voter < ActiveRecord::Base 
  include ProtectedModel
  
end

class Candidate < ActiveRecord::Base 
  include ProtectedModel
  
end