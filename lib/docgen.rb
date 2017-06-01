require "docgen/version"
require_relative "./db"
require_relative "./gen_text"
require_relative "./gen_html"
require_relative "./gen_latex"
require_relative "./gen_pdf"
require_relative "./zip_utils"

module Docgen
  include Db, ZipUtils

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

end
