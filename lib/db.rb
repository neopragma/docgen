require 'sqlite3'
require_relative "./settings"

module Db
  include Settings

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

  def substitution_text_for set_id, key
    auto_connect
    res = @substitutions.where(:set_id => set_id, :key => key).select(:value)
    res.get(:value)
  end

  def default_artifacts
    artifacts_for 'default'
  end

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