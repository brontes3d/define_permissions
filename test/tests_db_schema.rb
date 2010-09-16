ActiveRecord::Schema.define do

  create_table "candidates", :force => true do |t|
    t.string   "name"
  end

  create_table "voters", :force => true do |t|
    t.string   "name"
    t.integer  "election_id"
  end

  create_table "elections", :force => true do |t|
    t.integer   "vote_tally"
    t.integer   "exit_polls"
  end

end