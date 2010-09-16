$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'define_permissions'
require 'define_permissions/definition'
require 'define_permissions/actor'
require 'define_permissions/permission_not_defined'

require 'authorized_actor'

require 'protected_model'

require 'protected_controller'