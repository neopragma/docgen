require "spec_helper"
require 'nokogiri'
require_relative "./docgen_test"
require_relative "./db_helper"

include DbHelper

describe 'Microsoft PowerPoint (.pptx) manipulation' do

  before(:all) do
    load_basic_pptx_substitutions
    @basic_pptx_file = 'spec/data/basic-presentation-with-placeholders.pptx'
    @pptx_with_theme = 'spec/data/presentation-with-theme.pptx'
    @potx_theme = 'spec/data/my-theme.potx'
    @pptx_replacement_theme = 'spec/data/replacement-theme.pptx'
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

  it 'replaces placeholders with custom text on all slides (in zipped pptx)' do
    @docgen.process 1, 'pptx', @temp_pptx_file
    package = Zip::File.open(@temp_pptx_file)
  	package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
      doc = package.find_entry(entry)
      modified_slide = Nokogiri::XML.parse(doc.get_input_stream)
      match_replacement_text_in modified_slide
    end  
    package.close
  end

  it 'replaces the theme in a powerpoint presentation from another pptx' do
  	FileUtils.cp @pptx_with_theme, @temp_pptx_file
  	@docgen.process 1, 'pptx', @temp_pptx_file, @pptx_replacement_theme
  	begin
      package = Zip::File.open(@temp_pptx_file)
      theme_entry = package.find_entry('ppt/theme/theme1.xml')
      theme = Nokogiri::XML.parse(theme_entry.get_input_stream)
      expect(theme.xpath('/a:theme').attr('name').value).to eq 'Berlin'
    ensure
      package.close
    end  
  end

  it 'replaces the theme in a powerpoint presentation from a potx template file' do
  	FileUtils.cp @pptx_with_theme, @temp_pptx_file
  	@docgen.process 1, 'pptx', @temp_pptx_file, @potx_theme
  	begin
      package = Zip::File.open(@temp_pptx_file)
      theme_entry = package.find_entry('ppt/theme/theme1.xml')
      theme = Nokogiri::XML.parse(theme_entry.get_input_stream)
      expect(theme.xpath('/a:theme').attr('name').value).to eq 'My Theme'
    ensure
      package.close
    end  
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