require "sequel"
require "sqlite3"

module DbHelper

  def load_basic_text_substitutions
  	@conn = Sequel.connect('sqlite://docgen')
  	@substitutions = @conn.from(:substitutions)
  	@substitutions.delete
  	@substitutions.insert(:key => 'foo', :value => 'amazing')
  	@substitutions.insert(:key => 'bar', :value => 'dismal')
  end

  def disconnect
  	@conn.disconnect
  end

end