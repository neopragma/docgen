require "spec_helper"
require_relative "./docgen_test"
require_relative "./db_helper"

include DbHelper

describe 'Basic text substitution' do

  before(:all) do
    load_basic_text_substitutions
  end

  after(:all) do
    disconnect
  end

  before(:each) do
    @docgen = DocgenTest.new
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
