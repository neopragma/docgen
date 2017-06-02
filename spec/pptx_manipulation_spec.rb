require "spec_helper"
require_relative "./docgen_test"
require_relative "./db_helper"

include DbHelper

describe 'Microsoft PowerPoint (.pptx) manipulation' do

  before(:all) do
    load_basic_pptx_substitutions
  end

  after(:all) do
    disconnect
  end

  before(:each) do
    @docgen = DocgenTest.new
  end

  it 'replaces placeholders with custom text on a slide (extracted xml)' do
    original_slide = File.read('spec/data/pptx-slide-with-placeholders.xml', 
    	:encoding => 'utf-8')
  	modified_slide = @docgen.gen('text', original_slide)
  	expect(modified_slide).to match(/Mom and Pop Stores/)
  	expect(modified_slide).to match(/Copyright \u00A9 2017/)
  	expect(modified_slide).to match(/Custom bullet point one/)
  	expect(modified_slide).to match(/Custom bullet point two/)
  	expect(modified_slide).to match(/Custom bullet point three/)
  end

end