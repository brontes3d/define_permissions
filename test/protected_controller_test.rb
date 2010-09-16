require "#{File.dirname(__FILE__)}/test_helper.rb"

require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/test_process'

# ActionController::Routing::Routes.clear!
# ActionController::Routing::Routes.draw {|m| m.connect ':controller/:action/:id' }
# # ActionController::Routing::Routes.reload!

require "#{File.dirname(__FILE__)}/../init"

#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")

class ProtectedControllerTest < ActionController::TestCase
  
  def setup
    #require the mock models and controllers for the voting system for this test
    require File.expand_path(File.dirname(__FILE__) + '/protected_controller_voting_system/candidates_controller.rb')
    require File.expand_path(File.dirname(__FILE__) + '/protected_controller_voting_system/models.rb')
    
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_protected_controller
    AuthorizedActor.current_actor = AuthorizedActor::AnythingGoes.new
    me = Candidate.new
    me.name = "Jacob"
    me.save!
    other = Candidate.new
    other.name = "Jay"
    other.save!
    AuthorizedActor.current_actor = me
    
    @controller = CandidatesController.new
    
    #attempting to run an allowed action should proceed uninterupted
    get :edit, :id => me
    
    assert_response :success
    assert_equal("Jacob", @response.body)
    
    #attempting to run a not allowed action should yield 403 Forbidden
    get :edit, :id => other
    
    assert_response :forbidden
  end
  
end
