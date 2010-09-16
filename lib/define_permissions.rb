# DefinePermissions::FIND_DENIED is a contstant for use in DefinePermissions::Definition.find_permissions 
# when finding the given entity should never be allowed
#
# Example:
#
#   module VoterPermissions
#     include DefinePermissions::Definition
#   
#     find_permissions(Secret) do |me|
#        DefinePermissions::FIND_DENIED
#     end
#   end
# 
#
module DefinePermissions
  
  FIND_DENIED = {:conditions => [" 1 <> 1 "]}
    
end