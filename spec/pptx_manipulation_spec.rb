require "spec_helper"
require 'nokogiri'
require_relative "./docgen_test"
require_relative "./db_helper"

include DbHelper

describe 'Microsoft PowerPoint (.pptx) manipulation' do

  before(:all) do
    load_basic_pptx_substitutions
    @basic_pptx_file = 'spec/data/basic-presentation-with-placeholders.pptx'
    @temp_pptx_file = 'spec/data/temp.pptx'
  end

  after(:all) do
    disconnect
  end

  before(:each) do
    @docgen = DocgenTest.new
    FileUtils.rm_f @temp_pptx_file
    FileUtils.cp @basic_pptx_file, @temp_pptx_file
  end

  it 'replaces placeholders with custom text on a slide (in single extracted xml file)' do
    original_slide = File.read('spec/data/pptx-slide-with-placeholders.xml', 
    	:encoding => 'utf-8')
  	modified_slide = @docgen.gen('text', original_slide)
  	match_replacement_text_in modified_slide
  end

  it 'replaces placeholders with custom text on all slides (in zipped pptx)' do
    @docgen.process 'pptx', @temp_pptx_file
    package = Zip::File.open(@temp_pptx_file)
  	package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
      doc = package.find_entry(entry)
      modified_slide = Nokogiri::XML.parse(doc.get_input_stream)
      match_replacement_text_in modified_slide
    end  
    package.close
  end

  private

  def match_replacement_text_in modified_slide
  	expect(modified_slide).to match(/Mom and Pop Stores/)
  	expect(modified_slide).to match(/Copyright \u00A9 2017/)
  	expect(modified_slide).to match(/Custom bullet point one/)
  	expect(modified_slide).to match(/Custom bullet point two/)
  	expect(modified_slide).to match(/Custom bullet point three/)
  end

end