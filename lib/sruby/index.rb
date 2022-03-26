# frozen_string_literal: true

require "sqlite3"
require File.expand_path("mixin.rb", __dir__)
require File.expand_path("errors.rb", __dir__)

module Sruby
  class Database
    attr_reader :db

    # Creates a new database object
    # @param [String, Hash, Sqlite3::Database] options The database file to open, or a hash of options
    def initialize(options = Hash[:name => "sruby.db"])
      case options
      when String
        @db = SQLite3::Database.new(options)
      when Hash
        @db = SQLite3::Database.new(options[:name])
      when SQLite3::Database
        @db = options
      else
        raise SrubyError, "Invalid argument: #{options.inspect}"
      end
      @db.results_as_hash = true if options.is_a?(Hash) && options[:results_as_hash]
    end

    # Creates a new Table in database
    # @param [String] table_name The name of the table
    # @example
    # db = Sruby::Database.new
    # db.create_table("users")
    # @return [Table] The database object
    def create(table_name)
      @db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS #{table_name} (
          name TEXT PRIMARY KEY,
          value TEXT
        );
      SQL

      Database.attr_accessor table_name
      instance_variable_set("@#{table_name}", Table.new(@db, table_name))
      instance_variable_get("@#{table_name}")
    end

    # Insert values into a table
    # @param [String] table_name The name of the table
    # @param [String, Hash] values The values to insert
    # @example
    # db = Sruby::Database.new
    # db.create_table("users")
    # db.insert("users", "person" => "John", "age" => "24")
    # db.insert("users", Hash["person" => "John", "age" => "24"])
    # db.insert("users", "person", "John")
    # @return [Array] The database object
    def insert(table_name, *values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values_as_paths = values[0].paths
        values_as_paths.each do |path, value|
          p path, value
          @db.execute("INSERT INTO #{table_name} (name, value) VALUES (?, ?)", path.join("."), value)
        end
      else
        @db.execute("INSERT INTO #{table_name} (name, value) VALUES (?, ?)", values[0].to_s, values[1])
      end
    rescue SQLite3::ConstraintException
      raise SrubyError, "Duplicated key"
    end

    # Updates values in a table
    # @param [String] table_name The name of the table
    # @param [String, Hash] values The values to update
    # @example
    # db = Sruby::Database.new
    # db.create_table("users")
    # db.insert("users", "person" => "John", "age" => "24")
    # db.update("users", "person" => "John", "age" => "25")
    # db.update("users", Hash["person" => "John", "age" => "25"])
    # @return [Array] The database object
    def update(table_name, *values)
      case values[0]
      when Hash
        values[0].stringify_keys!
        values_as_paths = values[0].paths
        values_as_paths.each do |path, value|
          p path, value
          @db.execute("REPLACE INTO #{table_name} (name, value) VALUES (?, ?)", path.join("."), value)
        end
      else
        @db.execute("REPLACE INTO #{table_name} (name, value) VALUES (?, ?)", values[0].to_s, values[1])
      end
    end

    # Get a value from a table
    # @param [String] table_name The name of the table
    # @param [String] name The value to get
    # @param [Nil, String] path The path to get
    # @example
    # db = Sruby::Database.new
    # db.create_table("users")
    # db.insert("users", "person" => "John", "age" => "24")
    # db.get("users", "person")
    # @return [String] The value
    def get(table_name, name, path = nil)
      if path.nil?
        @db.execute("SELECT value FROM #{table_name} WHERE name = ?", name)
      else
        path_name = case path
                    when Array
                      "#{path.map(&:to_s).join(".")}.#{name}"
                    when String
                      "#{path}.#{name}"
                    else
                      name
                    end
        data = @db.execute("SELECT value FROM #{table_name} WHERE name = ?", path_name)
        raise SrubyError, "No value found for #{path_name}" if data.empty?
        data
      end
    end

    # Deletes a row from a table
    # @param [String] table_name The name of the table
    # @param [String] name The name of the row to delete
    # @param [Nil, String] path The path to delete
    # @example
    # db = Sruby::Database.new
    # db.create_table("users")
    # db.insert("users", "person" => "John", "age" => "24")
    # db.delete("users", "person")
    # @return [Array] The database object
    def delete(table_name, name, path = nil)
      if path.nil?
        @db.execute("DELETE FROM #{table_name} WHERE name = ?", name)
      else
        path_name = case path
                    when Array
                      "#{path.map(&:to_s).join(".")}.#{name}"
                    when String
                      "#{path}.#{name}"
                    else
                      name
                    end
        @db.execute("DELETE FROM #{table_name} WHERE name = ?", path_name)
      end
    end

    # Get all the values from a table
    # @param [String] table_name The name of the table
    # @return [Array] The values
    def all(table_name)
      @db.execute("SELECT * FROM #{table_name}")
    end
  end

  class Table
    attr_reader :db, :name

    def initialize(db, name)
      @db = db
      @name = name
    end

    def insert(*values)
      Database.new(@db).insert(@name, *values)
    end

    def update(*values)
      Database.new(@db).update(@name, *values)
    end

    def get(name, path = nil)
      Database.new(@db).get(@name, name, path)
    end

    def delete(name, path = nil)
      Database.new(@db).delete(@name, name, path)
    end

    def all
      Database.new(@db).all(@name)
    end
  end
end
