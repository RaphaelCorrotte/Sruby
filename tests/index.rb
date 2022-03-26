# frozen_string_literal: true

require_relative "../lib/sruby/index"

db = Sruby::Database.new
test = db.create("test")
db.test == test
test.insert("one" => 1)
test.insert("member" => Hash[:name=>"John", :age=>25])
test.delete("one")
test.all
db.all("test")
