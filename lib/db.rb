require 'sqlite3'
require_relative "./settings"

module Db
  include Settings

  DEFAULT = 'default'

  def connect dbname
    if File.exist?(dbname)
      @conn = Sequel.connect("sqlite://#{dbname}")
      @substitutions = @conn.from(:substitutions)
      @conn
    else
      raise "Unable to connect to database \"#{dbname}\""
    end
  end

  def close
  	@conn.disconnect
  	@conn = nil
  end

  # Returns the substitution value for a given document set and key
  def substitution_text_for set_id, key
    auto_connect
    res = @substitutions
      .where(:set_id => set_id, :key => key)
      .select(:value)
      .get(:value)
  end

  # Returns a list of all substitution values for the default document set
  def default_substitutions
    substitutions_for DEFAULT
  end

  # Returns a list of all substitution values for the specified document set name
  def substitutions_for set_name
    auto_connect
    @conn[:substitutions].select(:key, :value)
      .where(:set_id => @conn[:document_sets].select(:id).where(:name => set_name))
      .order(:key)
      .all
  end

  # Returns a list of the default artifacts
  def default_artifacts
    artifacts_for DEFAULT
  end

  # Returns a list of the artifacts for the specified document set name
  def artifacts_for set_name
    auto_connect
    @conn[:documents].select(:path)
      .where(:set_id => @conn[:document_sets].select(:id).where(:name => set_name))
      .order(:path)
      .all
  end

  private

  def auto_connect 
    connect settings('dbname') unless @conn
  end

end