require "#{File.dirname(__FILE__)}/test_helper.rb"
require "#{File.dirname(__FILE__)}/../init"

#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")


class DefinePermissionsTest < Test::Unit::TestCase
  include TestHelper
  
  def setup
    #require the mock models for the voting system for this test
    require File.expand_path(File.dirname(__FILE__) + '/d_p_voting_system/models.rb')
  end
  
  def test_permitted_for_action_on_model
    voter = Voter.new
    
    assert voter.check_permissions_for_action_on_model(:vote, Election), 
      "Expected voter to be permitted to vote in election"
    assert !voter.check_permissions_for_action_on_model(:rig, Election), 
      "Expected voter NOT to be permitted to rig election"
    
    assert voter.check_permissions_for_action_on_model(:something, SomethingOnlyInDefault), 
        "Expected voter to be permitted to something as defined in default permissions"
    assert !voter.check_permissions_for_action_on_model(:something_else, SomethingOnlyInDefault), 
        "Expected voter NOT to be permitted to something_else as defined in default permissions"

    assert voter.check_permissions_for_action_on_model(:thing, SomethingInPrimaryFallback), 
        "Expected voter to be permitted to do 'thing' as defined in PrimaryFallback"

    assert_raises(DefinePermissions::PermissionNotDefined){
      voter.check_permissions_for_action_on_model(:anything, SomethingNowhere)
    }
  end
  
  def test_permitted_for_named_thing
    voter = Voter.new
    
    assert_equal(['democrat', "republican", "independent"], voter.permitted(:political_parties))

    assert_equal(['thing'], voter.permitted(:thing_in_fallback))
    
    #TODO: test permitted for named thing where object is actually passed
    #TODO: do we ever need this where object is passed? how to enforce??!?! does it need enforcement??!?
    
    assert_raises(DefinePermissions::PermissionNotDefined){
      voter.permitted(:something_not_defined)      
    }
  end
  
  def test_check_field_permission
    voter = Voter.new
    
    assert !voter.check_field_permission(:create, Voter, nil, :id),
      "Expected voter NOT to be permitted to create a voter"

    assert voter.check_field_permission(:update, Voter, voter, :name),
      "Expected voter to be permitted to update self name"

    assert !voter.check_field_permission(:update, Voter, Voter.new, :name),
          "Expected voter NOT to be permitted to update name on another voter"

    assert voter.check_field_permission(:show, Voter, voter, :name),
      "Expected voter to be permitted to show self name"

    assert voter.check_field_permission(:show, Voter, Voter.new, :name),
      "Expected voter to be permitted to show another voter's name"

    assert !voter.check_field_permission(:show, Voter, voter, :something_else),
      "Expected voter NOT to be permitted to show self something_else"    

    assert voter.check_field_permission(:show, SomethingInPrimaryFallback, SomethingInPrimaryFallback.new, :name),
      "Expected SomethingInPrimaryFallback to be permitted to show "

    assert voter.check_field_permission(:show, SomethingOnlyInDefault, SomethingOnlyInDefault.new, :name),
      "Expected SomethingOnlyInDefault to be permitted to show "
      
    assert_raises(DefinePermissions::PermissionNotDefined){
      voter.check_field_permission(:show, SomethingNowhere, voter, :something_else)
    }
  end
  
  def test_get_find_scoping_conditions
    voter = Voter.new
    as_anything_goes_user do 
      voter.save!
    end
    
    assert_equal({}, voter.get_find_scoping_conditions(Election), 
      "Expected unrestricted find scoping on Election")
    assert_equal({:conditions=>["id = ?", voter.id]}, voter.get_find_scoping_conditions(Voter), 
      "Expected find scoping on Voter to be restricted to only me")

    assert_equal({}, voter.get_find_scoping_conditions(SomethingInPrimaryFallback), 
      "Expected unrestricted find scoping on SomethingInPrimaryFallback")
    assert_equal({}, voter.get_find_scoping_conditions(SomethingOnlyInDefault), 
      "Expected unrestricted find scoping on SomethingOnlyInDefault")

    assert_raises(DefinePermissions::PermissionNotDefined){
      voter.get_find_scoping_conditions(SomethingNowhere)
    }
  end
  
  #Test setting the current actor to a Voter 
      #and then searching for all voters, should only find 1 voter
      #and then updating name on self, should be allowed
      #and then update name on another voter, should be denied
      
      #and then attempting to vote on the election controller, should be allowed
      #and then attempting to rig on the election controller, should be denied
  
  
  
end
