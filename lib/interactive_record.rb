require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.name.downcase.pluralize
  end

  def self.column_names
    sql = "pragma table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    table_info.collect {|col| col['name']}
  end

  def initialize(hash= {})
    hash.each {|key, value| self.send("#{key}=", value)}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.drop(1).join(', ')
  end

  def values_for_insert
    "'#{self.class.column_names.drop(1).collect { |attr| send(attr) }.join("', '")}'"
  end

  def save
    sql = <<-SQL
    INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.class.column_names.drop(1).length.times.collect{"?"}.join(", ")})
    SQL

    DB[:conn].execute(sql, values_for_insert.split(', ').map { |attr| attr.delete("'")} )
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
        SELECT * FROM #{table_name}
        WHERE #{table_name}.name = ?
        SQL
        DB[:conn].execute(sql, name)
  end

  def self.find_by(hash)
    key = hash.keys.join('')
    value = hash.values.join('')
    sql = <<-SQL
    SELECT * FROM #{table_name}
    WHERE #{table_name}.#{key} = ?
    SQL
    DB[:conn].execute(sql, value)
  end
end