require "spec_helper"

describe 'Managing configuration settings' do

  before(:each) do
    @docgen = DocgenTest.new
  end

  it 'loads configuration settings' do
    expect(@docgen.settings('ziptemp')).to eq('ziptemp')
  end

end
