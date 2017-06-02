require 'nokogiri'
require_relative "./docgen"
require_relative "./db"

class ProcessPptx
  include Docgen, Db

  def process pptx_file
    package = Zip::File.open(pptx_file)
    apply_text_substitutions_to_slides_in package
    package.close
  end

  private

  def apply_text_substitutions_to_slides_in package
  	package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
      doc = package.find_entry(entry)
      original_slide = Nokogiri::XML.parse(doc.get_input_stream)
      modified_slide = gen 'text', original_slide.to_s
      package.get_output_stream(entry) { |f| f << modified_slide.to_s}
    end  
  end

end