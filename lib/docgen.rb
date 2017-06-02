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
  def process file_type, file_path
    processor_class_name = "Process#{file_type.split('_').collect(&:capitalize).join}"
    begin
      processor = Object::const_get("#{processor_class_name}").new
    rescue NameError => e
      raise "Undefined processor class: #{processor_class_name}"
    end
    processor.process file_path
  end

  # Substitute custom values for text placeholders
  def gen format_name, boilerplate, *template
  	content = apply_substitutions_to boilerplate
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

  def apply_substitutions_to boilerplate
    keys = boilerplate.scan(/(::.*?::)/m)
    return boilerplate unless keys.any?
    content = boilerplate
    keys.flatten!
    keys.each do |key|
      content = content.gsub(key,lookup(key))
    end
    content
  end

  def lookup key
    substitution_text_for key.gsub(/::/,'')
  end

  def settings name
    @settings[name]
  end

end
