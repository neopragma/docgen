require 'kramdown'

class GenLatex

  def format content, *template
  	use_template = template.any? ? template[0][0] : nil
    begin
      Kramdown::Document.new(content, :template => use_template).to_latex
    rescue RuntimeError => e
      puts "RuntimeError: #{e}"
      raise e
    end
  end

end