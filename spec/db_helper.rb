require "sequel"
require "sqlite3"

module DbHelper

  def load_basic_text_substitutions
    clear_substitutions
  	@substitutions.insert(:key => 'foo', :value => 'amazing')
  	@substitutions.insert(:key => 'bar', :value => 'dismal')
  end

  def load_basic_pptx_substitutions
    clear_substitutions
    @substitutions.insert(:key => 'client name', :value => 'Mom and Pop Stores')
    @substitutions.insert(:key => 'copyright notice', :value => "Copyright \u00A9 2017")
    @substitutions.insert(:key => 'bullet1', :value => 'Custom bullet point one')
    @substitutions.insert(:key => 'bullet2', :value => 'Custom bullet point two')
    @substitutions.insert(:key => 'bullet3', :value => 'Custom bullet point three')
  end

  def disconnect
  	@conn.disconnect
  end

  private

  def clear_substitutions
    @conn = Sequel.connect('sqlite://docgen')
    @substitutions = @conn.from(:substitutions)
    @substitutions.delete
  end

end