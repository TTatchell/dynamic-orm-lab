require_relative "../config/environment.rb"
require "active_support/inflector"
require "pry"

class InteractiveRecord

  ################Class Methods################

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].execute("PRAGMA table_info('#{self.table_name}')").collect { |column| column["name"] }.compact
  end

  def initialize(hash = {})
    hash.each { |k, v| self.send("#{k}=", v) unless v.nil? { instance_variable_set("@#{key}", nil) } }
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT * FROM #{self.table_name}
    WHERE name == ?
    LIMIT 1
    SQL
    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash)
    key, value = hash.first
    arg = key.to_s
    sql = <<-SQL
    SELECT * FROM #{table_name}
    WHERE #{arg} = ?
    SQL
    DB[:conn].execute(sql, value)
  end

  ################Instance Methods################

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    (self.class.column_names - ["id"]).join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    if self.id
    else
      sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid()")[0][0]
    end
  end
end
