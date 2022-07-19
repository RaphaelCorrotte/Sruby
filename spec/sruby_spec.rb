# frozen_string_literal: true

require "sruby"

RSpec.describe Sruby do
  it "has a version number" do
    expect(Sruby::VERSION).not_to be nil
  end

  it "works" do
    db = Sruby::Database.new
    db.create("test")
    expect(db["test"]).to eq(db.test)
  end
end
