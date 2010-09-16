require "#{File.dirname(__FILE__)}/test_helper.rb"
require "#{File.dirname(__FILE__)}/../init"

#setup active record to use a sqlite database
# ActiveRecord::Base.configurations = {"test"=>{"dbfile"=>"test.db", "adapter"=>"sqlite3"}}
# ActiveRecord::Base.establish_connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/tests_db_schema.rb")

class PermissionUndefinedTest < Test::Unit::TestCase
  
  def setup
    #require the mock models for the voting system for this test
    require File.expand_path(File.dirname(__FILE__) + '/d_p_voting_system/models.rb')
    
    DefinePermissions::Actor.class_eval do
      alias_method :original_handle_permission_undefined, :handle_permission_undefined
      def handle_permission_undefined(failure)
        return failure.backtrace
      end
    end
  end
  
  def teardown
    DefinePermissions::Actor.class_eval do
      alias_method :handle_permission_undefined, :original_handle_permission_undefined
    end
  end
  
  def test_permitted_for_action_on_model
    voter = Voter.new
    
    result = voter.permitted(:anything, SomethingNowhere)
    
    assert result, "Expecting an exception to actually be raised (so that it has a backtrace)"
  end

end
