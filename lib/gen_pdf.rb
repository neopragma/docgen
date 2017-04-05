require 'kramdown'
require 'prawn'
require "prawn/table"

class GenPdf

  def format content, *template
  	use_template = template.any? ? template[0][0] : nil
  	# Suppress a warning message regarding UTF-8 font support
  	Prawn::Font::AFM.hide_m17n_warning = true
    begin
      Kramdown::Document.new(content, :template => use_template).to_pdf
    rescue RuntimeError => e
      raise e
    end
  end

end