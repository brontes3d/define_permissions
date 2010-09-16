require "#{File.dirname(__FILE__)}/test_helper.rb"

require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/test_process'

ActionController::Routing::Routes.clear!
ActionController::Routing::Routes.draw {|m| m.connect ':controller/:action/:id' }

ActionController::Base.view_paths = [File.join(File.expand_path(File.dirname(__FILE__)), 'protected_fields_voting_system/views')]


require "#{File.dirname(__FILE__)}/../init"

#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")

class ProtectedFieldsTest < ActionController::TestCase
  
  def setup
    #require the field helper plugin and the protect_fields component of this plugin
    require File.expand_path(File.dirname(__FILE__) + '/../../field_helper/init')
    require "#{File.dirname(__FILE__)}/../lib/protect_fields"
    
    #require the mock models and controllers for the voting system for this test    
    require File.expand_path(File.dirname(__FILE__) + '/protected_fields_voting_system/models.rb')
    require File.expand_path(File.dirname(__FILE__) + '/protected_fields_voting_system/controllers.rb')
    
    
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    AuthorizedActor.current_actor = AuthorizedActor::AnythingGoes.new
    @the_election = Election.new
    @the_election.vote_tally = 5
    @the_election.exit_polls = 3
    @the_election.save!
    @me_candidate = Candidate.new
    @me_candidate.save!
    @me_voter = Voter.new
    @me_voter.save!
  end
  
  #candidate 'edit' election can edit the vote_tally and can't even see the exit_polls
  def test_candiate_edit_election
    AuthorizedActor.current_actor = @me_candidate
    
    @controller = ElectionsController.new
  
    #attempting to run an allowed action should proceed uninterupted
    get :edit, :id => @the_election.id
    assert_response :success
    
    # puts "should see edit for vote tally"
    # puts @response.body
    
    assert(@response.body.index("editing vote tally"), "Expected to see edit for vote tally")
    
    assert(!@response.body.index("showing exit polls"), "Expected to see nothing for exit polls")
    assert(!@response.body.index("editing exit polls"), "Expected to see nothing for exit polls")
  end
    
  #voter 'edit' election can edit only edit exit_polls, and can only see the vote_tally
  def test_voter_edit_election
    AuthorizedActor.current_actor = @me_voter
    
    @controller = ElectionsController.new

    #attempting to run an allowed action should proceed uninterupted
    get :edit, :id => @the_election.id
    assert_response :success
    
    # puts "should see edit exit_polls and see show for vote_tally"
    # puts @response.body
        
    assert(@response.body.index("editing exit polls"), "Expected to see edit for exit polls")
    assert(@response.body.index("showing vote tally"), "Expected to see show for vote tally")
  end
  
  
  #candidate 'show' election gets no edit fields, can't see exit polls
  def test_candiate_show_election
    AuthorizedActor.current_actor = @me_candidate
    
    @controller = ElectionsController.new
  
    #attempting to run an allowed action should proceed uninterupted
    get :show, :id => @the_election.id
    assert_response :success
    
    # puts "should see vote_tally no exit_polls"
    # puts @response.body
    
    assert(@response.body.index("showing vote tally"), "Expected to see show for vote tally")

    assert(!@response.body.index("showing exit polls"), "Expected to see nothing for exit polls")
    assert(!@response.body.index("editing exit polls"), "Expected to see nothing for exit polls")    
  end
  
  #voter 'show' election get no edit fields, can see exit polls
  def test_voter_show_election
    AuthorizedActor.current_actor = @me_voter
    
    @controller = ElectionsController.new
  
    #attempting to run an allowed action should proceed uninterupted
    get :show, :id => @the_election.id
    assert_response :success
    
    # puts "should see vote_tally and exit_polls"
    # puts @response.body
    
    assert(@response.body.index("showing exit polls"), "Expected to see show for exit polls")
    assert(@response.body.index("showing vote tally"), "Expected to see show for vote tally")        
  end
  
  
  
  
end
