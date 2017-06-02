require 'nokogiri'
require_relative "./docgen"
require_relative "./db"

class ProcessPptx
  include Docgen, Db

  def process pptx_file, template
    package = Zip::File.open(pptx_file)
    apply_text_substitutions_to_slides_in package
    replace_presentation_theme_in( package, template ) unless template.empty?
    package.close
  end

  private

  def apply_text_substitutions_to_slides_in package
  	package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
      doc = package.find_entry(entry)
      original_slide = Nokogiri::XML.parse(doc.get_input_stream)
      modified_slide = gen 'text', original_slide.to_s
      package.get_output_stream(entry) { |f| f << modified_slide.to_s }
    end  
  end

  def replace_presentation_theme_in package, template
  	theme_entry_name = 'ppt/theme/theme1.xml'
    theme_source = Zip::File.open(template[0])
    replacement_theme_entry = theme_source.find_entry(theme_entry_name)
    replacement_theme = Nokogiri::XML.parse(replacement_theme_entry.get_input_stream)
    original_theme = package.find_entry(theme_entry_name)
    package.get_output_stream(original_theme) { |f| f << replacement_theme.to_s }
    theme_source.close
  end

end