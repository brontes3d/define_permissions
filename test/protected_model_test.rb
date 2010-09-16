require "#{File.dirname(__FILE__)}/test_helper.rb"
require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")

class ProtectedModelTest < Test::Unit::TestCase
  
  def setup
    #require the mock models for the voting system for this test
    require File.expand_path(File.dirname(__FILE__) + '/protected_model_voting_system/models.rb')    
  end
  
  def test_voter_find_permissions_for_voters
    AuthorizedActor.current_actor = AuthorizedActor::AnythingGoes.new    
    some_other_voter = Voter.new
    some_other_voter.name = "shadowy figure"
    some_other_voter.save!
    me = Voter.new
    me.name = "me"
    me.save!
    AuthorizedActor.current_actor = me
    
    #should find myself and not the some_other_voter
    found_voters = Voter.find(:all)
    
    assert(found_voters.include?(me), "Expected to find me in the found_voters")

    assert(!found_voters.include?(some_other_voter), "Expected NOT to find some_other_voter in the found_voters")
    
    found_voters = Voter.find_all_by_name("shadowy figure")
    assert(!found_voters.include?(some_other_voter), "Expected NOT to find some_other_voter in the found_voters (using find_all_by_name)")    

    found_voters = Voter.find_all_by_name("me")
    assert(found_voters.include?(me), "Expected to find me in the found_voters (using find_all_by_name)")
    
    assert_nil Voter.find_by_name("shadowy figure")
  end
  
  def test_voter_can_update_self_name_but_not_others
    AuthorizedActor.current_actor = AuthorizedActor::AnythingGoes.new    
    some_other_voter = Voter.new
    some_other_voter.save!
    me = Voter.new
    me.save!
    AuthorizedActor.current_actor = me
    
    assert_nothing_raised{
      me.name = "Bob"
      me.save!
    }
    
    assert_raises(SecurityError){
      some_other_voter.name = "Fred"
      some_other_voter.save!      
    }
  end
  
  def test_after_find_permission_checks_finds_inconsistencies
    AuthorizedActor.current_actor = AuthorizedActor::AnythingGoes.new 
    obama = Candidate.new
    obama.save!
    me = Voter.new
    me.save!
    AuthorizedActor.current_actor = me
    
    #should raise exception about inconsistencies
    assert_raises(SecurityError){
      found_voters = Candidate.find(:all)
    }
  end
  
  
  
end
