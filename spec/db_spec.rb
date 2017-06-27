require "spec_helper"
require 'sequel'
require_relative "../lib/db"

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

  context 'data retrieval convenience methods' do

  	it 'retrieves list of paths/uris for default artifacts' do
  	  expected_results = [{:path=>"dir1/doc1.txt"}, {:path=>"dir1/doc2.txt"}]
  	  expect(@db.default_artifacts).to eq(expected_results)
  	end

    it 'retrieves list of paths/uris for Gotham City Police Department' do
  	  expected_results = [{:path=>"gcpd/doc1.txt"}, {:path=>"gcpd/doc2.txt"}]
  	  expect(@db.artifacts_for('gcpd')).to eq(expected_results)
    end

  end

end
