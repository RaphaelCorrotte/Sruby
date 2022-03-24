# frozen_string_literal: true

class Hash
  def stringify_keys!
    transform_keys!(&:to_s)
  end

  def stringify_values!
    transform_values!(&:to_s)
  end

  # Get the deepest keys
  # @param hash [Hash] the hash to get the deepest keys from
  # @return [Array<String>] the deepest keys
  def keys(hash = self)
    hash.each_with_object([]) do |(key, value), paths|
      if value.is_a?(Hash)
        paths.concat(keys(value))
      else
        paths << key
      end
    end
  end

  # Get the deep path of a certain key
  # @param key [String] the key to get the path for
  # @param path [Array] the current path
  # @return [NilClass, Array<String, String>] the path to the key
  def path_to(key, path = [], hash: self)
    hash.stringify_keys!
    hash.each_pair do |k, v|
      return [path + [k], v] if k == key.to_s
      if v.is_a?(Hash) &&
        (p = path_to(key.to_s, path + [k], :hash => v))
        return p
      end
    end
    nil
  end

  def paths(hash = self)
    keys(hash).map { |key| path_to(key, :hash => hash) }
  end
end
