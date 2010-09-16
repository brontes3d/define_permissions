ActionController::Routing::Routes.draw do |map| 
  # map.connect 'candidates/edit/:id', :controller => 'candidates', :action => 'edit'
  map.connect ':controller/:action/:id' 
end
