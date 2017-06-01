require "spec_helper"
require "sequel"
require "sqlite3"

class DocgenTest
  include Docgen
end

describe Docgen do

  before(:all) do
  	DB = Sequel.connect('sqlite://docgen')
  	@substitutions = DB.from(:substitutions)
  	@substitutions.delete
  	@substitutions.insert(:key => 'foo', :value => 'amazing')
  	@substitutions.insert(:key => 'bar', :value => 'dismal')
  end

  after(:all) do
  	DB.disconnect
  end

  before(:each) do
    @docgen = DocgenTest.new
  end

  describe 'structural attributes' do

    it "has a version number" do
      expect(Docgen::VERSION).not_to be nil
    end

  end

  describe 'handle expected errors' do

    it "raises RuntimeError when an unsupported output format is specified" do
      expect{ @docgen.gen('foo', 'Content') }
        .to raise_error(RuntimeError, /Unsupported output format: foo/)
    end

    it "raises RuntimeError when the specified template file can\'t be found" do
      expect{ @docgen.gen('pdf', 'Content', 'nosuchtemplate') }
        .to raise_error(RuntimeError, 'The specified template file nosuchtemplate does not exist')
    end

  end

  describe 'zip and unzip' do

    it 'reads the entries in a zip file' do
      expected_content = ["this is the entry \'dir1/dir11/file111\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir1/file11\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir1/file12\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir2/dir21/dir221/file2221\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir2/file21\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'file1\' in my test archive!\n\nIt has only a few lines.\n"]
      expect(@docgen.unzip('spec/data/zipWithDirs.zip')).to eq(expected_content)
    end

    it 'saves extracted files in a directory' do
      expected_result = ["ziptemp/dir2", "ziptemp/dir2/file21", "ziptemp/dir2/dir21", "ziptemp/dir2/dir21/dir221", "ziptemp/dir2/dir21/dir221/file2221", "ziptemp/dir1", "ziptemp/dir1/file11", "ziptemp/dir1/dir11", "ziptemp/dir1/dir11/file111", "ziptemp/dir1/file12", "ziptemp/file1"]
      @docgen.unzip('spec/data/zipWithDirs.zip')
      expect(Dir[File.join('ziptemp', '**', '*')]).to eq(expected_result)
    end

  end


  describe 'text output' do

    it "outputs plain text with no substitutions" do
      expect(@docgen.gen('text', 'Here is some text.'))
        .to eq('Here is some text.')  
    end

    it "outputs plain text with one substitution in the middle" do
      expect(@docgen.gen('text', 'Here is ::foo:: text.'))
        .to eq('Here is amazing text.')  
    end

    it "outputs plain text with one substitution at the beginning" do
      expect(@docgen.gen('text', '::foo:: text is here.'))
        .to eq('amazing text is here.')  
    end

    it "outputs plain text with one substitution at the end" do
      expect(@docgen.gen('text', 'The text that is here is truly ::foo::.'))
        .to eq('The text that is here is truly amazing.')  
    end

    it "outputs plain text with two substitutions" do
      expect(@docgen.gen('text', 'This text is ::foo::, but this text is ::bar::.'))
        .to eq('This text is amazing, but this text is dismal.')  
    end

  end

  describe 'html output' do

    it "outputs a single html paragraph with no substitutions" do
      expect(@docgen.gen('html', 'Here is some text.')).to eq("<p>Here is some text.</p>\n")  
    end

    it "outputs some assorted html elements with no substitutions" do
      expect(@docgen.gen('html', "# Heading level 1 {#head1}\n\nFoods:\n\n- pizza\n- fried eggs\n\nHave a nice day."))
      	.to eq("<h1 id=\"head1\">Heading level 1</h1>\n\n<p>Foods:</p>\n\n<ul>\n  <li>pizza</li>\n  <li>fried eggs</li>\n</ul>\n\n<p>Have a nice day.</p>\n")  
    end

    it "outputs some assorted html elements with substitutions" do
      expect(@docgen.gen('html', "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day."))
      	.to eq("<h1 id=\"head1\">Heading level 1</h1>\n\n<p>Foods:</p>\n\n<ul>\n  <li>amazing pizza</li>\n  <li>dismal fried eggs</li>\n</ul>\n\n<p>Have a nice day.</p>\n")  
    end

    it "outputs an html document with substitutions" do
      expected_html_document = "<!DOCTYPE html>\n<html>\n" +  
        "  <head>\n    \n" \
      	"    <meta http-equiv=\"Content-type\" content=\"text/html;charset=UTF-8\">\n    \n\n" \
        "    <title>Heading level 1</title>\n" \
        "    <meta name=\"generator\" content=\"kramdown 1.13.2\" />\n" \
        "  </head>\n" \
        "  <body>\n" \
        "  <h1 id=\"head1\">Heading level 1</h1>\n\n" \
        "<p>Foods:</p>\n\n<ul>\n  <li>amazing pizza</li>\n  <li>dismal fried eggs</li>\n</ul>\n\n<p>Have a nice day.</p>\n\n" \
        "  </body>\n" \
        "</html>\n"

      expect(@docgen.gen('html', 
      	  "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day.",
      	  'document'))
      	.to eq(expected_html_document)
    end

  end

  describe 'latex output' do

    it "outputs a single latex paragraph with no substitutions" do
      expect(@docgen.gen('latex', 'Here is some text.')).to eq("Here is some text.\n\n")  
    end

    it "outputs some assorted latex elements with no substitutions" do
      expect(@docgen.gen('latex', "# Heading level 1 {#head1}\n\nFoods:\n\n- pizza\n- fried eggs\n\nHave a nice day."))
      	.to eq("\\section{Heading level 1}\\hypertarget{head1}{}\\label{head1}\n\nFoods:\n\n\\begin{itemize}\n\\item pizza\n\\item fried eggs\n\\end{itemize}\n\nHave a nice day.\n\n")  
    end

    it "outputs some assorted latex elements with substitutions" do
      expect(@docgen.gen('latex', "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day."))
      	.to eq("\\section{Heading level 1}\\hypertarget{head1}{}\\label{head1}\n\nFoods:\n\n\\begin{itemize}\n\\item amazing pizza\n\\item dismal fried eggs\n\\end{itemize}\n\nHave a nice day.\n\n")  
    end

    it "outputs a latex document with substitutions" do
      expected_latex_document = 
        "\n" \
        "\\documentclass{scrartcl}" \
        "\n" \
        "\n" \
        "\\usepackage[utf8x]{inputenc}" \
        "\n" \
        "\n" \
        "\\usepackage[T1]{fontenc}" \
        "\n" \
        "\\usepackage{listings}" \
        "\n" \
        "\n" \
        "\\usepackage{hyperref}" \
        "\n" \
        "\n" \
        "\n" \
        "\n" \
        "\n" \
        "\n" \
        "\\setcounter{footnote}{0}" \
        "\n" \
        "\n" \
        "\\hypersetup{colorlinks=true,urlcolor=blue}" \
        "\n" \
        "\n" \
        "\\begin{document}" \
        "\n" \
        "\\section{Heading level 1}\\hypertarget{head1}{}\\label{head1}" \
        "\n" \
        "\n" \
        "Foods:" \
        "\n" \
        "\n" \
        "\\begin{itemize}" \
        "\n" \
        "\\item amazing pizza" \
        "\n" \
        "\\item dismal fried eggs" \
        "\n" \
        "\\end{itemize}" \
        "\n" \
        "\n" \
        "Have a nice day." \
        "\n" \
        "\n" \
        "\n" \
        "\\end{document}" \
        "\n" 

      expect(@docgen.gen('latex', 
      	    "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day.",
      	    'document'))
      	.to eq(expected_latex_document)  
    end

  end

  describe 'pdf output' do

    it "outputs a pdf document with substitutions" do

#      File.open('temp.pdf', 'w') {|f| f.write(@docgen.gen('pdf', 
#      	    "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day.")) }

      expect(@docgen.gen('pdf', 
      	    "# Heading level 1 {#head1}\n\nFoods:\n\n- ::foo:: pizza\n- ::bar:: fried eggs\n\nHave a nice day."))
      	.to match(/^%PDF-1\.3(.*)/)  
    end

  end

end
