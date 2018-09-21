require "spec_helper"
require_relative "./docgen_test"

describe 'Managing configuration settings' do

  before(:each) do
    @docgen = DocgenTest.new
  end

  it 'loads configuration settings' do
    expect(@docgen.settings('ziptemp')).to eq('ziptemp')
  end

  it 'retrieves database name' do
    expect(@docgen.settings('dbname')).to eq('docgen')
  end

end
