require 'nokogiri'
require_relative "./docgen"
require_relative "./db"
require_relative "./settings"

# 1. Insert one or more sets of slides into the pptx_file, if specified.
# 2. Replace text placeholders with values for the document set, if any.
# 3. Replace the presentation theme, if one is specified.
class ProcessPptx
  include Docgen, Db, Settings

    PATH_TO_PPT = 'ppt'
    PATH_TO_PPT_RELS = 'ppt/_rels'
    PATH_TO_SLIDE_RELS = 'ppt/slides/_rels'
    SLIDES_START_WITH = 'ppt/slides/slide'
    PRESENTATION_XML = 'presentation.xml'
    PRESENTATION_XML_RELS = 'presentation.xml.rels'

  def process document_set, pptx_file, *other_args
    parse_arguments other_args
    initialize_work_files
    begin
      package = Zip::File.open(pptx_file)
      insert_slides_in package, other_args[0][0] if @insert_slides
      apply_text_substitutions_to_slides_in document_set, package
      replace_presentation_theme_in( package, @template ) unless @template == nil
    ensure
      package.close
    end
  end

  private

  # other_args are arguments specific to pptx processing
  #
  # other_args may contain one or both of:
  # - the path to a template file (potx or ppts) containing a theme
  # - an array of SlideSet objects containing slides to be inserted
  #   into the pptx_file. Both those arguments are optional.
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
    insert_slide_entries_in package, slide_sets
    renumber_slides_after_insertion_in package
    add_rels_entries_after_insertion_in package
    update_presentation_rels_in package
    update_presentation_xml_entry_in package
  end  

  def insert_slide_entries_in package, slide_sets
      @original_slide_count = package.entries.map(&:name).select{|i| i.start_with?(SLIDES_START_WITH)}.size
      package.entries.map(&:name).select{|i| i.start_with?(SLIDES_START_WITH)}.sort.each do |original_entry_name|
        doc = package.find_entry(original_entry_name)
        original_slide = Nokogiri::XML.parse(doc.get_input_stream)
        slide_sets.each do |slide_set|
          pattern = Regexp.new(slide_set.name).freeze
          if pattern.match?(original_slide)

            slide_number = 0
            slide_set.package.entries.map(&:name).select{|i| i.start_with?(SLIDES_START_WITH)}.sort.each do |entry_name|

              # ppt/slide entries from the source package

              extracted_entry_name = "#{original_entry_name.chomp('.xml')}_#{slide_number}.xml"
              slide_set.package.extract(entry_name, "#{@tempdir}/#{extracted_entry_name}")
              package.add("#{extracted_entry_name}", "#{@tempdir}/#{extracted_entry_name}")
              slide_number += 1
            end
          end
        end
      end       
      @slide_count = package.entries.map(&:name).select{|i| i.start_with?(SLIDES_START_WITH)}.size
  end

  def renumber_slides_after_insertion_in package
    slide_number = @slide_count
    package.entries.map(&:name).select{|i| i.start_with?('ppt/slides/slide')}.sort.reverse_each do |modified_entry_name|
      name_start = modified_entry_name.slice(0..(modified_entry_name.index(SLIDES_START_WITH) + SLIDES_START_WITH.length))
      package.rename(modified_entry_name, "#{SLIDES_START_WITH}#{slide_number}.xml") unless package.find_entry("#{SLIDES_START_WITH}#{slide_number}.xml")
      slide_number -= 1
    end
  end

# First attempt: Add ppt/slides/_rels/slideN.xml.rels with <Relatioship Id="rId1" ... Target="../slideLayouts/slideLayout1.xml">
# for all entries in ppt/slides. That is, copy the entry ppt/slides/_rels/slide1.xml.rels from the original deck for each new entry.
# This will probably not be accurate for complicated slide decks. All rels point to rId1 and slideLayout1
# in the simple test deck I made for purposes of this rspec example. Inserted slides don't automatically have a corresponding entry in
# ppt/slides/_rels. (Note to self: Extract this info to the project wiki once the details have been worked out.)
  def add_rels_entries_after_insertion_in package
    extracted_file_name = "#{@tempdir}/base_slide_rel_name"
    slide_number = @slide_count
    @slide_count.times do
      remove_file extracted_file_name
      base_slide_rel_name = "#{PATH_TO_SLIDE_RELS}/slide1.xml.rels"
      package.extract base_slide_rel_name, extracted_file_name 
      slide_rel_entry_name = "#{PATH_TO_SLIDE_RELS}/slide#{slide_number}.xml.rels"
      package.add slide_rel_entry_name, extracted_file_name unless package.find_entry slide_rel_entry_name
      slide_number -= 1
    end
  end

  # Add elements in ppt/_rels/presentation.xml.rels for the inserted slides
  # Increment Id value and slide number from the last Relationship node for a slide
  def update_presentation_rels_in package
    rels_entry_name = "#{PATH_TO_PPT_RELS}/#{PRESENTATION_XML_RELS}"
    temp_file_name = "#{@tempdir}/#{PRESENTATION_XML_RELS}"
    remove_file temp_file_name
    package.extract rels_entry_name, temp_file_name

    raw_text = get_text_from temp_file_name
    # Nokogiri can't handle the xmlns attribute on the Relationships node
    raw_text.gsub!(/xmlns/,'snlmx')
    xml_doc = xml_doc_from raw_text
    last_relationship = xml_doc.xpath('/Relationships/Relationship[starts-with(@Target, "slides/slide")]').last
    last_id_value = last_relationship['Id'] # Id value looks like 'rId8' (ugh!)
    last_id_value = last_id_value[3..last_id_value.length].to_i
    last_slide_number = last_relationship['Target'].gsub(/slides\/slide/,'').gsub(/.xml/,'').to_i
    rels_type = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide"
    
    # Add a Relationship element for each new slide inserted into the deck. 
    rels_count = @slide_count - @original_slide_count
    slide_number = @original_slide_count + 1
    rels_count.times do 
      last_id_value += 1
      last_id_value_str = 'rId' + last_id_value.to_s
      rels_node = Nokogiri::XML::Node.new('Relationship',xml_doc)
      rels_node['Id'] = last_id_value_str
      rels_node['Type'] = rels_type
      rels_node['Target'] = "slides/slide#{slide_number.to_s}.xml"
      xml_doc.xpath('//Relationships/Relationship').last.add_next_sibling(rels_node)
      slide_number += 1
    end
    updated_xml = xml_doc.to_s.gsub(/snlmx/,'xmlns')  # reverse the workaround for Nokogiri
    remove_file temp_file_name
    new_rels_xml = File.open(temp_file_name, "w")
    new_rels_xml.puts updated_xml
    new_rels_xml.close 
    package.replace rels_entry_name, temp_file_name
  end

  # Add elements to ppt/presentation.xml for the inserted slides
  def update_presentation_xml_entry_in package
    presentation_entry_name = "#{PATH_TO_PPT}/#{PRESENTATION_XML}"
    temp_file_name = "#{@tempdir}/#{PRESENTATION_XML}"
    remove_file temp_file_name
    package.extract presentation_entry_name, temp_file_name
    raw_text = get_text_from temp_file_name
    modified_text = raw_text.gsub(/:/,'__') # workaround - namespaces not declared in presentation.xml
    xml_doc = xml_doc_from modified_text

    # Start with the last sldId element in the document
    last_sldId_element = xml_doc.xpath("//p__presentation/p__sldIdLst").last.last_element_child
    last_sldId_id_value = last_sldId_element['id'].to_i
    last_sldId_rid_value = last_sldId_element['r__id'] # r:id value looks like 'rId8' (ugh!)
    last_sldId_rid_value = last_sldId_rid_value[3..last_sldId_rid_value.length].to_i

    # Add a p:sldId element for each new slide inserted into the deck. 
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
      
    updated_xml = xml_doc.to_s.gsub(/__/,':') # reverse the workaround for namespace prefixes
    remove_file temp_file_name
    new_presentation_xml = File.open(temp_file_name, "w")
    new_presentation_xml.puts updated_xml
    new_presentation_xml.close 
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

  def get_text_from file_name
    IO.read(file_name).gsub(/\n/,'')
  end

  def xml_doc_from text
    Nokogiri::XML(text) { |config| config.strict }
  end

  def initialize_work_files
    @tempdir = settings 'ziptemp'
    FileUtils.rm_rf "#{@tempdir}"
    FileUtils.mkdir_p "#{@tempdir}/#{PATH_TO_SLIDE_RELS}"
  end

  def remove_file file_name   
    FileUtils.rm file_name if File.exists? file_name
  end

end