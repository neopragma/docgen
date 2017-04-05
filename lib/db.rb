require 'sqlite3'

module Db

  def connect
    begin
      @conn = Sequel.connect('sqlite://docgen')
      @substitutions = DB.from(:substitutions)
    rescue 
      puts 'connection error' 
    end
  end

  def close
  	@conn.disconnect
  	@conn = nil
  end

  def substitution_text_for key
    connect unless @conn
    res = @substitutions.where(:key => key).select(:value)
    res.get(:value)
  end

end