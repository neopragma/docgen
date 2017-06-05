require "spec_helper"

describe 'Error handling' do

  before(:each) do
    @docgen = DocgenTest.new
  end

  it "raises RuntimeError when an undefined file type processor is specified" do
    expect{ @docgen.process('default', 'foo', '') }
      .to raise_error(RuntimeError, /Undefined processor class: ProcessFoo/)
  end

  it "raises RuntimeError when an unsupported output format is specified" do
    expect{ @docgen.gen('default', 'foo', 'Content') }
      .to raise_error(RuntimeError, /Unsupported output format: foo/)
  end

  it "raises RuntimeError when the specified template file can\'t be found" do
    expect{ @docgen.gen('default', 'pdf', 'Content', 'nosuchtemplate') }
      .to raise_error(RuntimeError, 'The specified template file nosuchtemplate does not exist')
  end

end
