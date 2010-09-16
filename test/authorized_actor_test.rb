require "#{File.dirname(__FILE__)}/test_helper.rb"
require "#{File.dirname(__FILE__)}/../init"


#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")


class AuthorizedActorTest < Test::Unit::TestCase
  include TestHelper
  
  def setup
    #require the mock models for the voting system for this test
    require File.expand_path(File.dirname(__FILE__) + '/a_a_voting_system/models.rb')
  end
  
  def test_default_authorized_actor_guest    
    Thread.current['current_actor'] = nil
    
    assert_equal(AuthorizedActor::Guest, AuthorizedActor.current_actor.class, 
      "Expecting current_actor to default o a AuthorizedActor::Guest when not set")
      
    #guest should be permitted to do nothing
    assert !AuthorizedActor.current_actor.permitted(:vote, Election), 
      "Expected guest NOT to be permitted to vote in election"

    assert !AuthorizedActor.current_actor.permitted(:something), 
      "Expected guest NOT to be permitted to something"
      
    assert !AuthorizedActor.current_actor.check_field_permission(:create, Voter, nil, :id),
      "Expected guest NOT to be permitted to create a voter"
      
    assert_equal(DefinePermissions::FIND_DENIED, AuthorizedActor.current_actor.get_find_scoping_conditions(Election), 
      "Expected guest to have find scoping that prevents the retrieval of everything")
  end
  
  def test_authorized_actor_anything_goes
    as_anything_goes_user do
      #anything_goes_user should be permitted to do everything
      assert AuthorizedActor.current_actor.permitted(:vote, Election), 
        "Expected anything_goes_user to be permitted to vote in election"
      
      assert AuthorizedActor.current_actor.permitted(:something), 
        "Expected anything_goes_user to be permitted to something"
      
      assert AuthorizedActor.current_actor.check_field_permission(:create, Voter, nil, :id),
        "Expected anything_goes_user to be permitted to create a voter"
      
      assert_equal({}, AuthorizedActor.current_actor.get_find_scoping_conditions(Election), 
        "Expected anything_goes_user to have no find scoping")
    end
  end
  
  #Voter should be allowed to be set as an authorized actor
  def test_voter_as_authorized_actor
    election = Election.new
    voter = Voter.new
    voter.election = election
    as_anything_goes_user do 
      voter.save!
      election.save!
    end
    # AuthorizedActor.current_actor = voter
    
    as_user(voter) do
      assert AuthorizedActor.current_actor.check_permissions_for_action_on_model(:vote, Election), 
        "Expected voter to be permitted to vote in election"
      
      assert AuthorizedActor.current_actor.check_permissions_for_action_on_model(:belong_in, Election, election), 
        "Expected voter to belong_in the election it belongs_to"
      
      assert AuthorizedActor.current_actor.check_permissions_for_action_on_model(:belong_in, Election, Proc.new{ election }), 
        "Expected voter to belong_in a Proc that returns the election it belongs_to"
      
      assert !AuthorizedActor.current_actor.check_permissions_for_action_on_model(:belong_in, Election, nil), 
        "Expected voter to not belong_in a nil election"
      
      assert !AuthorizedActor.current_actor.check_permissions_for_action_on_model(:belong_in, Election, Election.new), 
        "Expected voter to not belong_in an election it does not belong_to"
      
      assert !AuthorizedActor.current_actor.check_permissions_for_action_on_model(:rig, Election), 
        "Expected voter NOT to be permitted to rig election"
    end
  end
  
  #Setting a model that doesn't include Actor should raise an exception
  def test_candidate_as_authorized_actor
    candidate = Candidate.new
    as_anything_goes_user do
      candidate.save!
    end
    
    assert_raises(ArgumentError){
      AuthorizedActor.current_actor = candidate
    }
  end
  
end
