# frozen_string_literal: true

require "sqlite3"
require File.expand_path("mixin.rb", __dir__)
require File.expand_path("errors.rb", __dir__)

module Sruby
  class Database
    attr_reader :db

    def initialize(options = Hash[:name => "sruby.db"])
      case options
      when String
        @db = SQLite3::Database.new(options)
      when Hash
        @db = SQLite3::Database.new(options[:name])
      else
        raise SrubyError, "Invalid argument: #{options.inspect}"
      end
      @db.results_as_hash = true if options.is_a?(Hash) && options[:results_as_hash]
    end

    def create(table_name)
      @db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS #{table_name} (
          name TEXT PRIMARY KEY,
          value TEXT
        );
      SQL
      define_singleton_method(table_name.downcase) do
        Table.new(@db, table_name)
      end
    end

    def insert(table_name, *values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values_as_paths = paths(values[0])
        values_as_paths.each do |path, value|
          p path, value
          @db.execute("INSERT INTO #{table_name} (name, value) VALUES (?, ?)", path.join("."), value)
        end
      else
        @db.execute("INSERT INTO #{table_name} (name, value) VALUES (?, ?)", values[0].to_s, values[1])
      end
    end

    def update(table_name, *values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values[0].each do |value|
          @db.execute("REPLACE INTO #{table_name} (name, value) VALUES (?, ?)", value)
        end
      else
        @db.execute("REPLACE INTO #{table_name} (name, value) VALUES (?, ?)", values[0].to_s, values[1])
      end
    end

    def find(table, conditions = {})
      conditions.stringify_keys!
      conditions.stringify_values!
      @db.execute("SELECT * FROM  #{table} WHERE #{conditions.map { |k, v| "#{k} = '#{v}'" }.join(" AND ")}")
    end

    def get(table_name, name, path = nil)
      if path.nil?
        @db.execute("SELECT value FROM #{table_name} WHERE name = ?", name)
      else
        path_name = path.concat(name)
        @db.execute("SELECT value FROM #{table_name} WHERE name = ?", path_name)
      end
    end

    def all(table_name)
      @db.execute("SELECT * FROM #{table_name}")
    end

    def keys(hash)
      hash.each_with_object([]) do |(key, value), paths|
        if value.is_a?(Hash)
          paths.concat(keys(value))
        else
          paths << key
        end
      end
    end

    def path_to(hash, key, path = [])
      hash.stringify_keys!
      hash.each_pair do |k, v|
        return [path + [k], v] if k == key.to_s
        if v.is_a?(Hash) &&
          (p = path_to(v, key.to_s, path + [k]))
          return p
        end
      end
      nil
    end

    def paths(hash)
      keys(hash).map { |key| path_to(hash, key) }
    end

    private :keys, :path_to
  end

  class Table
    attr_reader :db, :name

    def initialize(db, name)
      @db = db
      @name = name
    end

    def insert(*values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values[0].each do |value|
          @db.execute("INSERT INTO #{@name} (name, value) VALUES (?, ?)", value)
        end
      else
        @db.execute("INSERT INTO #{@name} (name, value) VALUES (?, ?)", values[0].to_s, values[2])
      end
    end

    def update(*values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values[0].each do |value|
          @db.execute("REPLACE INTO #{@name} (name, value) VALUES (?, ?)", value)
        end
      else
        @db.execute("REPLACE INTO #{@name} (name, value) VALUES (?, ?)", values[0].to_s, values[2])
      end
    end

    def get(name)
      @db.execute("SELECT value FROM #{@name} WHERE name = ?", name).first
    end

    def all
      @db.execute("SELECT * FROM #{@name}")
    end
  end
end
