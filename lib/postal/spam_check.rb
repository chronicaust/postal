# frozen_string_literal: true

module Postal
  class SpamCheck

    attr_reader :code, :score, :description

    def initialize(code, score, description = nil)
      @code = code
      @score = score
      @description = description.to_s.first(250)
    end

    def to_hash
      {
        code: code,
        score: score,
        description: description
      }
    end

  end
end
