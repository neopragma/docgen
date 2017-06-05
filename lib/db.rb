require 'sqlite3'

module Db

  def connect
    begin
      @conn = Sequel.connect('sqlite://docgen')
      @substitutions = @conn.from(:substitutions)
    rescue Exeption => e
      puts "Database connection error: #{e.message}"
    end
  end

  def close
  	@conn.disconnect
  	@conn = nil
  end

  def substitution_text_for set_id, key
    connect unless @conn
    res = @substitutions.where(:set_id => set_id, :key => key).select(:value)
    res.get(:value)
  end

end