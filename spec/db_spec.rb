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

    it 'retrieves list of default text substitutions' do
      expected_results = [
        {:key=>"bar", :value=>"dismal"},
        {:key=>"bullet1", :value=>"Custom bullet point one"},
        {:key=>"bullet2", :value=>"Custom bullet point two"},
        {:key=>"bullet3", :value=>"Custom bullet point three"},
        {:key=>"client name", :value=>"Mom and Pop Stores"},
        {:key=>"copyright notice", :value=>"Copyright \\u00A9 2017"},
        {:key=>"delivery team", :value=>"Delivery Team"},
        {:key=>"foo", :value=>"amazing"},
        {:key=>"iteration", :value=>"Sprint"},
        {:key=>"ivt", :value=>"Innovation and Verification Team"},
        {:key=>"portfolio team", :value=>"Portfolio Team"},
        {:key=>"product owner", :value=>"Product Owner"},
        {:key=>"program team", :value=>"Program Team"},
        {:key=>"tlt", :value=>"Transformation Leadership Team"},
        {:key=>"value stream", :value=>"Line of Business"}
      ]
      expect(@db.default_substitutions).to eq(expected_results)
    end

    it 'retrieves list of text substitutions for Gotham City Police Department' do
      expected_results = [
      	{:key=>"bar", :value=>"Penguin"},
      	{:key=>"client name", :value=>"Gotham City Police Dept."},
      	{:key=>"delivery team", :value=>"Development Pod"},
      	{:key=>"foo", :value=>"Batman"},
        {:key=>"iteration", :value=>"Development Cadence"},
        {:key=>"ivt", :value=>"Architectural Guidance Committee"},
        {:key=>"portfolio team", :value=>"Product Line Team"},
        {:key=>"product owner", :value=>"Capability Owner"},
        {:key=>"program team", :value=>"Coordination Team"},
        {:key=>"tlt", :value=>"Improvement Guidance Committee"},
      	{:key=>"value stream", :value=>"Product Line"}
      ]
      expect(@db.substitutions_for('gcpd')).to eq(expected_results)
    end

  end

end
