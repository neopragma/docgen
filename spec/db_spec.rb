require "spec_helper"
require 'sequel'

describe 'Persistence' do

  class DbTest
    include Db 
  end	

  before(:each) do
    @db = DbTest.new
  end

  context 'connections' do

   	it 'connects to the specified database' do
   	  expect(@db.connect('docgen').uri).to match(/sqlite:\/\/docgen/)
    end

    it 'raises error when the specified database does not exist' do
      expect{ @db.connect('nosuchdatabase') }
        .to raise_error(RuntimeError, /Unable to connect to database "nosuchdatabase"/)
    end
  end

end
