# frozen_string_literal: true

module Sruby
  class SrubyError < StandardError
    def initialize(msg = String.new)
      super("SRUBY ERROR : #{msg}")
    end
  end
end
