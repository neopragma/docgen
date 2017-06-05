require "docgen/version"
require_relative "./db"
require_relative "./gen_text"
require_relative "./gen_html"
require_relative "./gen_latex"
require_relative "./gen_pdf"
require_relative "./settings"
require_relative "./zip_utils"
require_relative "./process_pptx"

module Docgen
  include Db, Settings, ZipUtils

  # Apply customizations to a complex file type such as pptx, xlsx, docx, odp, ods, odt)
  def process document_set, file_type, file_path, *template
    processor_class_name = "Process#{file_type.split('_').collect(&:capitalize).join}"
    begin
      processor = Object::const_get("#{processor_class_name}").new
    rescue NameError => e
      raise "Undefined processor class: #{processor_class_name}"
    end
    processor.process document_set, file_path, template
  end

  # Substitute custom values for text placeholders
  def gen document_set, format_name, boilerplate, *template
  	content = apply_substitutions_to document_set, boilerplate
    get_formatter(format_name).format content, template
  end

  def get_formatter format_name
  	formatter_class_name = "Gen#{format_name.split('_').collect(&:capitalize).join}"
    begin
      formatter = Object::const_get("#{formatter_class_name}").new
    rescue NameError => e
      raise "Unsupported output format: #{format_name}"
    end  
  end

  def apply_substitutions_to document_set, boilerplate
    keys = boilerplate.scan(/(::.*?::)/m)
    return boilerplate unless keys.any?
    content = boilerplate
    keys.flatten!
    keys.each do |key|
      content = content.gsub(key,lookup(document_set, key))
    end
    content
  end

  def lookup document_set, key
    substitution_text_for document_set, key.gsub(/::/,'')
  end

  def settings name
    @settings[name]
  end

end
