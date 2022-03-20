# frozen_string_literal: true

class Hash
  def stringify_keys!
    transform_keys!(&:to_s)
  end

  def stringify_values!
    transform_values!(&:to_s)
  end
end
