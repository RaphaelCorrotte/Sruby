# frozen_string_literal: true

require_relative "../lib/sruby/index"

db = Sruby::Database.new
test = db.create("test")
db.test == test
test.insert("one", 1)
test.insert(Hash["two", 2, "three", 3])
test.all
db.all("test")
