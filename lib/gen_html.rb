require 'kramdown'

class GenHtml

  def format content, *template
  	use_template = template.any? ? template[0][0] : nil
    begin
      Kramdown::Document.new(content, :template => use_template).to_html
    rescue
      puts 'in rescue block'
    end
  end

end