require "#{File.dirname(__FILE__)}/test_helper.rb"

require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/test_process'

require "#{File.dirname(__FILE__)}/../init"


#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")


class ProtectedControllerIntTest < ActionController::IntegrationTest
  include TestHelper
  
  def setup
    ActionController::Routing::Routes.clear!
    ActionController::Routing.controller_paths += [ File.expand_path(File.dirname(__FILE__)) + '/protected_controller_voting_system' ]
    ActionController::Routing::Routes.add_configuration_file(File.expand_path(File.dirname(__FILE__)) + '/rails/config/routes.rb')
    ActionController::Routing::Routes.reload!
    
    ActionController::Base.session = { :key => "_myapp_session", :secret => "3a0cd488ce7c73b3fdc6a6974cd08de0" }
    
    # load the controllers
    # ActionController::Routing.controller_paths.each do |path|
    #   Dir["#{path}/*.rb"].each { |f| require f }
    # end
    require "#{File.expand_path(File.dirname(__FILE__))}/protected_controller_voting_system/candidates_controller.rb"
    require "#{File.expand_path(File.dirname(__FILE__))}/protected_controller_voting_system/models.rb"
    
    @controller = CandidatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_protected_controller
    me = Candidate.new
    other = Candidate.new
    
    as_anything_goes_user do 
      me.name = "Jacob"
      me.save!
      
      other.name = "Jay"
      other.save!
    end
    
    
    as_user(me) do
      # attempting to run an allowed action should proceed uninterupted
      get url_for(:controller => 'candidates', :action => 'edit', :id => me.id)
      assert_response :success
      assert_equal("Jacob", @response.body)
      
      # attempting to run a not allowed action should yield 403 Forbidden
      get url_for(:controller => 'candidates', :action => 'edit', :id => other.id)
      
      assert_response :forbidden
      
      # attempting to run a action that does not exist for the controller should yield 404 Not Found
      get url_for(:controller => 'candidates', :action => 'i_dont_exist')
      
      assert_response :not_found
    end
  end
  
  
  
end
