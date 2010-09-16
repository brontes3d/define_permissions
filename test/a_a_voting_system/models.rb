#extends d_p_voting system
require File.expand_path(File.dirname(__FILE__) + '/../d_p_voting_system/models.rb')

class Voter < ActiveRecord::Base 
  include AuthorizedActor
  
end