class CandidatesController < ActionController::Base
  include ProtectedController
  
  rescue_from SecurityError do |ex|
    # puts "SecurityError with params = #{params.inspect}"
    # puts "caller.join(\\n) :\n #{caller.join("\n")} \n\n"
    render :text => ex.message, :status => :forbidden
  end
  
  def edit
    # puts "CandidatesController#edit with params = #{params.inspect}"
    # puts "caller.join(\\n) :\n #{caller.join("\n")} \n\n"
    render :text => current_object.name
  end

  protected
  
  #normally this comes from make_resourceful
  def current_object
    # puts "CandidatesController#current_object with params = #{params.inspect}"
    # puts "caller.join(\\n) :\n #{caller.join("\n")} \n\n"
    Candidate.find(params[:id])
  end
  
end