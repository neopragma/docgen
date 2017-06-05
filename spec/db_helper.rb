require "sequel"
require "sqlite3"

module DbHelper

  def load_basic_text_substitutions
    clear_substitutions
    @substitutions.insert(:set => 'default', :key => 'foo', :value => 'amazing')
    @substitutions.insert(:set => 'default', :key => 'bar', :value => 'dismal')
    @substitutions.insert(:set => 'gcpd', :key => 'foo', :value => 'Batman')
    @substitutions.insert(:set => 'gcpd', :key => 'bar', :value => 'Penguin')
  end

  def load_basic_pptx_substitutions
    clear_substitutions
    @substitutions.insert(:set => 'default', :key => 'client name', :value => 'Mom and Pop Stores')
    @substitutions.insert(:set => 'default', :key => 'copyright notice', :value => "Copyright \u00A9 2017")
    @substitutions.insert(:set => 'default', :key => 'bullet1', :value => 'Custom bullet point one')
    @substitutions.insert(:set => 'default', :key => 'bullet2', :value => 'Custom bullet point two')
    @substitutions.insert(:set => 'default', :key => 'bullet3', :value => 'Custom bullet point three')
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