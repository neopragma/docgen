require "spec_helper"
require 'nokogiri'
require_relative "./docgen_test"
require_relative "./db_helper"
require_relative "../lib/slide_set"

include DbHelper

describe 'Microsoft PowerPoint (.pptx) manipulation' do

  before(:all) do
    load_basic_pptx_substitutions
    @basic_pptx_file = 'spec/data/basic-presentation-with-placeholders.pptx'
    @pptx_with_theme = 'spec/data/presentation-with-theme.pptx'
    @potx_theme = 'spec/data/my-theme.potx'
    @pptx_replacement_theme = 'spec/data/replacement-theme.pptx'
    @temp_pptx_file = 'spec/data/temp.pptx'
    @insertion_target_pptx = 'spec/data/insertion_target.pptx'
    @source_pptx_1 = 'spec/data/group_1_slides_for_insertion.pptx'
    @source_pptx_2 = 'spec/data/group_2_slides_for_insertion.pptx'
  end

  after(:all) do
    disconnect
  end

  before(:each) do
    @docgen = DocgenTest.new
    FileUtils.rm_f @temp_pptx_file
    FileUtils.cp @basic_pptx_file, @temp_pptx_file
  end

  context 'text replacement on slides' do

    it 'replaces placeholders with custom text on all slides (in zipped pptx)' do
      @docgen.process 1, 'pptx', @temp_pptx_file
      begin
        package = Zip::File.open(@temp_pptx_file)
  	    package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
          doc = package.find_entry(entry)
          modified_slide = Nokogiri::XML.parse(doc.get_input_stream)
          match_replacement_text_in modified_slide
        end
      ensure    
        package.close
      end
    end

  end
  
  context 'theme replacement in powerpoint packages' do  

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

  end

  context "slide insertion in powerpoint packages" do
    
    it 'inserts slides at defined insertion points in the pptx file' do
      # setup
      FileUtils.cp @insertion_target_pptx, @temp_pptx_file
      slide_sets = [ 
        SlideSet.new("Insertion point 1", Zip::File.open(@source_pptx_1)),
        SlideSet.new("Insertion point 2", Zip::File.open(@source_pptx_2))
      ]

      # action
      @docgen.process 1, 'pptx', @temp_pptx_file, slide_sets

      # check
      expected_slide_order = [ 
        "Test deck", 
        "Base slide 1", 
        "Insertion point 1",
        "Group 1 slide 1",
        "Group 1 slide 2",
        "Base slide 2",
        "Insertion point 2",
        "Group 2 slide 1",
        "Group 2 slide 2",
        "Base slide 3" ]

      slide_index = 0
      begin 
        package = Zip::File.open(@temp_pptx_file)
#        package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.sort.each do |entry_name|

#puts "expected_slide_order.size is #{expected_slide_order.size}"

         expected_slide_order.size.times do
#          doc = package.find_entry(entry_name)
          slide_number = slide_index +1

#puts "looking up slide number #{slide_number}"

          entry = package.find_entry("ppt/slides/slide#{slide_number}.xml")
          current_slide = Nokogiri::XML.parse(entry.get_input_stream)

#puts "Found entry #{entry}, matching on #{expected_slide_order[slide_index]}"

          expect(current_slide).to match /#{expected_slide_order[slide_index]}/ 
          slide_index += 1
        end
      ensure
        package.close        
      end
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