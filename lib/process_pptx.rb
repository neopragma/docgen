require 'nokogiri'
require_relative "./docgen"
require_relative "./db"
require_relative "./settings"

class ProcessPptx
  include Docgen, Db, Settings

  # 1. Insert one or more sets of slides into the pptx_file, if specified.
  # 2. Replace text placeholders with values for the document set. if any.
  # 3. Replace the presentation theme, if one is specified.
  #
  # other_args may contain the path to a template file containing a theme
  # and/or an array of SlideSet objects containing slides to be inserted
  # into the pptx_file. Both those arguments are optional.
  def process document_set, pptx_file, *other_args
    @slides_start_with = 'ppt/slides/slide'
    @tempdir = settings 'ziptemp'
    template = nil
    unless other_args.empty?
      if other_args[0][0].is_a?(String)
        template = other_args.shift
      end
      unless other_args.empty?
        if other_args[0][0].is_a?(Array) && other_args[0][0][0].is_a?(SlideSet)
          insert_slides_in pptx_file, other_args[0][0]
        end
      end  
    end  
    package = Zip::File.open(pptx_file)
    apply_text_substitutions_to_slides_in document_set, package
    replace_presentation_theme_in( package, template ) unless template == nil
    package.close
  end

  # Insert slides at specified locations in the PowerPoint package.
  # pptx_sources is an array of PptxSource objects.
  def insert_slides_in pptx_file, slide_sets
    FileUtils.rm_rf "#{@tempdir}"
    FileUtils.mkdir_p "#{@tempdir}/ppt/slides/_rels"
    begin
      package = Zip::File.open(pptx_file)
      package.entries.map(&:name).select{|i| i.start_with?(@slides_start_with)}.sort.each do |original_entry_name|
        doc = package.find_entry(original_entry_name)
        original_slide = Nokogiri::XML.parse(doc.get_input_stream)
        slide_sets.each do |slide_set|
          pattern = Regexp.new(slide_set.name).freeze
          if pattern.match?(original_slide)

            slide_number = 0
            slide_set.package.entries.map(&:name).select{|i| i.start_with?(@slides_start_with)}.sort.each do |entry_name|

              # ppt/slide entries from the source package

              extracted_entry_name = "#{original_entry_name.chomp('.xml')}_#{slide_number}.xml"
              slide_set.package.extract(entry_name, "#{@tempdir}/#{extracted_entry_name}")
              package.add("#{extracted_entry_name}", "#{@tempdir}/#{extracted_entry_name}")

#temp
              just_added = package.find_entry("#{extracted_entry_name}")
puts "just added entry #{just_added.to_s}"

# TODO: ppt/slides/_rels
# TODO: ppt/slideLayouts
# TODO: ppt/slideLayouts/_rels
# TODO: ppt/presentation.xml

              slide_number += 1

            end
          end
        end
      end  

      # renumbering the slides - this results in the correct numbering
      # needs to modify related entries in the package that point to each other so that PowerPoint can show the slides
      slide_number = package.entries.map(&:name).select{|i| i.start_with?(@slides_start_with)}.size
      package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.sort.reverse_each do |modified_entry_name|
        name_start = modified_entry_name.slice(0..(modified_entry_name.index(@slides_start_with) + @slides_start_with.length))
        package.rename(modified_entry_name, "#{@slides_start_with}#{slide_number}.xml") unless package.find_entry("#{@slides_start_with}#{slide_number}.xml")
        slide_number -= 1
      end



    ensure  
      package.close
    end
  end  

  private

  def interpret_optional_arguments *other_args
  end

  def apply_text_substitutions_to_slides_in document_set, package
  	package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.each do |entry|
      doc = package.find_entry(entry)
      original_slide = Nokogiri::XML.parse(doc.get_input_stream)
      modified_slide = gen document_set, 'text', original_slide.to_s
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