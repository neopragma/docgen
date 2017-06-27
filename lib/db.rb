require 'sqlite3'

module Db

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
    connect(settings('dbname')) unless @conn
    res = @substitutions.where(:set_id => set_id, :key => key).select(:value)
    res.get(:value)
  end

end