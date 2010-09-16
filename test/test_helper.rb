require 'rubygems'
require 'test/unit/notification'
require 'test/unit'

# set Rails env CONSTANT (we are not actually loading rails in this test, but ActiveRecord depends on this constant)
RAILS_ENV = 'test' unless defined?(RAILS_ENV)
require 'active_record'


module TestHelper
  
  def TestHelper.included(base)
    base.class_eval do
      def get_anything_goes_user
        @@do_anything_actor ||= AuthorizedActor::AnythingGoes.new
      end
    end
  end
  
  
  def as_anything_goes_user
    user_was = AuthorizedActor.current_actor
    AuthorizedActor.current_actor = self.get_anything_goes_user
    yield
  ensure
    AuthorizedActor.current_actor = user_was
  end
  
  def as_user(user, &block)
    # Setup for the block to run as the user parameter
    original_current_actor = AuthorizedActor.current_actor
    AuthorizedActor.current_actor = user
    yield
  ensure
    # Set back the AuthorizedActor.current_actor to its original value
    AuthorizedActor.current_actor = original_current_actor
  end
  
end