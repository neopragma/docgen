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
  #
  # and/or an array of SlideSet objects containing slides to be inserted
  #
  # into the pptx_file. Both those arguments are optional.
  def process document_set, pptx_file, *other_args
    parse_arguments other_args
    @slides_start_with = 'ppt/slides/slide'
    @tempdir = settings 'ziptemp'
    package = Zip::File.open(pptx_file)
    insert_slides_in package, other_args[0][0] if @insert_slides
    apply_text_substitutions_to_slides_in document_set, package
    replace_presentation_theme_in( package, @template ) unless @template == nil
    package.close
  end

  private

  def parse_arguments other_args
    @template = nil
    @insert_slides = false
    unless other_args.empty?
      if other_args[0][0].is_a?(String)
        @template = other_args.shift
      end
      unless other_args.empty?
        if other_args[0][0].is_a?(Array) && other_args[0][0][0].is_a?(SlideSet)
          @insert_slides = true
        end
      end  
    end  
  end

  def insert_slides_in package, slide_sets
    FileUtils.rm_rf "#{@tempdir}"
    FileUtils.mkdir_p "#{@tempdir}/ppt/slides/_rels"
    insert_slide_entries_in package, slide_sets
    renumber_slides_after_insertion_in package
    add_rels_entries_after_insertion_in package

# TODO: ppt/_rels/presentation.xml.rels

    update_presentation_xml_entry_in package
  end  

  def insert_slide_entries_in package, slide_sets
      @original_slide_count = package.entries.map(&:name).select{|i| i.start_with?(@slides_start_with)}.size
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
              slide_number += 1
            end
          end
        end
      end       
      @slide_count = package.entries.map(&:name).select{|i| i.start_with?(@slides_start_with)}.size
  end

  def renumber_slides_after_insertion_in package
    slide_number = @slide_count
    package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.sort.reverse_each do |modified_entry_name|
      name_start = modified_entry_name.slice(0..(modified_entry_name.index(@slides_start_with) + @slides_start_with.length))
      package.rename(modified_entry_name, "#{@slides_start_with}#{slide_number}.xml") unless package.find_entry("#{@slides_start_with}#{slide_number}.xml")
      slide_number -= 1
    end
  end

  def add_rels_entries_after_insertion_in package
# First attempt: Add ppt/slides/_rels/slideN.xml.rels with <Relatioship Id="rId1" ... Target="../slideLayouts/slideLayout1.xml">
# for all entries in ppt/slides. That is, copy the entry ppt/slides/_rels/slide1.xml.rels from the original deck for each new entry.
# This will probably not be accurate for complicated slide decks. All rels point to rId1 and slideLayout1
# in the simple test deck I made for purposes of this rspec example. Inserted slides don't automatically have a corresponding entry in
# ppt/slides/_rels. (Note to self: Extract this info to the project wiki once the details have been worked out.)
    extracted_file_name = "#{@tempdir}/base_slide_rel_name"
    slide_number = @slide_count
    @slide_count.times do
      FileUtils.rm extracted_file_name if File.exists? extracted_file_name
      base_slide_rel_name = 'ppt/slides/_rels/slide1.xml.rels'
      package.extract base_slide_rel_name, extracted_file_name 
      slide_rel_entry_name = "ppt/slides/_rels/slide#{slide_number}.xml.rels"
      package.add slide_rel_entry_name, extracted_file_name unless package.find_entry slide_rel_entry_name
      slide_number -= 1
    end
  end

  def update_presentation_xml_entry_in package
    # ppt/presentation.xml contains malformed XML. Entries are prefixed with namepace names, but they aren't declared.
    # Some rigamarole is necessary to work around this.

    # Extract the presentation.xml entry from the pptx package using rubyzip
    presentation_entry_name = 'ppt/presentation.xml' 
    temp_file_name = "#{@tempdir}/presentation.xml"
    FileUtils.rm temp_file_name if File.exists? temp_file_name
    package.extract presentation_entry_name, temp_file_name

    # Get the raw text from the extracted file. 
    # Remove newlines as these will be converted into useless XML text nodes by Nokogiri.
    raw_text = IO.read(temp_file_name).gsub(/\n/,'')

    # Replace the namespace prefix delimiters with plain text so Nokogiri can process the XML. 
    # This will change 'p:presentation' to 'p__presentation' and so forth. 
    # This is a workaround for the fact the namespaces aren't declared in the presentation.xml file.
    modified_text = raw_text.gsub(/:/,'__')

    # Make a Nokogiri document out of the munged XML text.
    xml_doc = Nokogiri::XML(modified_text)

    # Get the last sldId element in the document and save the id and r:id values so we can increment them. 
    # The id value is an integer as a string. The r:id value looks like 'rId8'.
    last_sldId_element = xml_doc.xpath("//p__presentation/p__sldIdLst").last.last_element_child
    last_sldId_id_value = last_sldId_element['id'].to_i
    last_sldId_rid_value = last_sldId_element['r__id']
    last_sldId_rid_value = last_sldId_rid_value[3..last_sldId_rid_value.length].to_i

    # ppt/presentation.xml needs a p:sldId element for each slide in the deck. 
    # For now, we're going to increment the id and r:id values and add an element for each new slide.
    # This may or may not be sufficient for more-complicated pptx files.
    sldId_count = @slide_count - @original_slide_count
    slide_number = @original_slide_count + 1
    sldId_count.times do 
      # increment the id values and create a new child element under p:presentation/p:sldIdLst
      last_sldId_id_value += 1
      last_sldId_rid_value += 1
      sldId_rid_value_str = 'rId' + last_sldId_rid_value.to_s
      sldId_node = Nokogiri::XML::Node.new('p__sldId',xml_doc)
      sldId_node['id'] = last_sldId_id_value.to_s
      sldId_node['r__id'] = sldId_rid_value_str
      xml_doc.xpath("//p__presentation/p__sldIdLst")[0] << sldId_node  
      slide_number += 1
    end
      
    # Reverse the text replacement to restore the namespace prefixes.
    updated_xml = xml_doc.to_s.gsub(/__/,':')
    FileUtils.rm temp_file_name
    new_presentation_xml = File.open(temp_file_name, "w")
    new_presentation_xml.puts updated_xml
    new_presentation_xml.close 

    # Replace the ppt/presentation.xml entry in the pptx with the modified one.
    package.replace presentation_entry_name, temp_file_name
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