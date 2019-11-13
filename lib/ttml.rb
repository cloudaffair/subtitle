require_relative "engines/translator"
require_relative "utils/common_utils"
require_relative "utils/cue_info"
require_relative "allfather"

require "nokogiri"

#
# Library to handle TTML Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class TTML

  include AllFather
  include CommonUtils

  SUPPORTED_TRANSFORMATIONS = [TYPE_SCC, TYPE_SRT, TYPE_VTT, TYPE_DFXP]

  def initialize(cc_file, opts=nil)
    @cc_file = cc_file
    @force_detect = opts ? (opts[:force_detect] || false) : false
    raise "Invalid TTML file provided" unless is_valid?
  end

  def callsign
    TYPE_TTML
  end

  def is_valid?
    # Do any VTT specific validations here
    if @cc_file =~ /^.*\.(ttml)$/
      return true
    end
    # TODO: Check if it's required to do a File read to see if this
    # a well-formed XML. Another is to see if lang is available in each div
    return false
  end

  def set_translator(translator)
    @translator = translator
  end

  def infer_languages
    lang = []
    begin
      xml_file = File.open(@cc_file)
      xml_doc  = Nokogiri::XML(xml_file)
      div_objects = xml_doc.css("/tt/body/div")
      local_force_detect = false
      div_objects.each_with_index do |div, index|
        # By default, return the lang if specified in the div and 
        # force detect is false
        inferred_lang = div.attributes['lang'].value rescue nil
        if inferred_lang.nil?
          # If lang is not provided in the caption, then override
          # force detect for inferrence
          local_force_detect = true
        end
        if @force_detect || local_force_detect
          local_force_detect = false
          sample_text = get_text(div, 100)
          inferred_lang = @translator.infer_language(sample_text) rescue nil
          if inferred_lang.nil?
            err_msg = "Failed to detect lang for div block number #{index + 1}"
            unless lang.empty?
              err_msg += "; Detected languages before failure are #{lang}"
            end
            raise AllFather::LangDetectionFailureException.new(err_msg)
          end
        end
        lang << inferred_lang
      end
    rescue StandardError => e
      puts "Error while detecting the language due to #{e.message}"
    ensure
      xml_file.close rescue nil
    end
    return nil if lang.empty?
    lang
  end

  def translate(src_lang, dest_lang, out_file)
    super(src_lang, dest_lang, out_file)
    xml_file = File.open(@cc_file, 'r:UTF-8', &:read)
    xml_doc  = Nokogiri::XML(xml_file)
    div_objects = xml_doc.css("/tt/body/div")
    # Irrespective of what lang the div xml:lang says, infer the lang and then
    # check to see if it matches src_lang
    matched_div = nil
    div_objects.each do |div|
      sample_text = get_text(div, 100)
      inferred_lang = @translator.infer_language(sample_text) rescue nil
      next if inferred_lang.nil?
      if inferred_lang.eql?(src_lang)
        matched_div = div 
        break 
      end
    end
    if matched_div.nil?
      FileUtils.remove_file(out_file)
      raise AllFather::InvalidInputException.new("Unable to find #{src_lang} language section in TTML")
    end
    # Update the Lang in the Div
    matched_div.lang = dest_lang

    blocks = matched_div.css("p")
    blocks.each do |block|
      # Multiple spaces being stripped off
      text = block.inner_html.strip.gsub(/(\s){2,}/, '')
      text_blocks = get_block_text(text)
      translated_text = ""
      text_blocks.each do |text_block|
        if text_block.start_with?('<') || text_block.empty?
          translated_text << text_block
          next
        end
        translated_resp = @translator.translate(text_block, src_lang, dest_lang)
        translated_text << translated_resp
      end
      block.inner_html = translated_text
    end
    xml_file.close rescue nil
    File.write(out_file, xml_doc)
    out_file
  end

  def supported_transformations
    return SUPPORTED_TRANSFORMATIONS
  end

  def transform_to(types, src_lang, target_lang, output_dir)
    # Let's start off with some validations
    super(types, src_lang, target_lang, output_dir)

    # Suffix output dir with File seperator
    output_dir = "#{output_dir}#{File::Separator}" unless output_dir.end_with?(File::Separator)
    
    # Prepare the output files for each type and for each lang in the file
    begin
      xml_file = File.open(@cc_file, 'r')
      xml_doc = Nokogiri::XML(xml_file)
      div_objects = xml_doc.css("/tt/body/div")
      langs = div_objects.map {|div| div.attributes['lang'].value rescue nil}

      matching_divs = []
      if src_lang.nil? || src_lang.empty?
        # Then we will have to create output files for each lang
        matching_divs = div_objects
      else
        # Find the matching lang div and create the outputs
        unless langs.include?(src_lang)
          raise InvalidInputException.new("Given Caption file #{@cc_file} doesn't contain #{src_lang} lang. Available langs are #{langs}")
        end
        available_divs = langs.select { |lang| lang.eql?(src_lang) }
        if available_divs.length > 1
          raise InvalidInputException.new("More than one section in Caption file specifies lang as #{src_lang}. This file is unsupported")
        end
        div_objects.each_with_index do |div, j|
          lang = div.attributes['lang'].value rescue nil
          if lang.nil?
            # Let's infer the lang
            if @translator.nil?
              raise StandardError.new("Cannot infer language as engine options are not provided")
            end
            reference_text = get_text(div, 100)
            inferred_lang = @translator.infer_language(reference_text) rescue nil
            if inferred_lang.nil?
              raise LangDetectionFailureException.new("Failed to infer language for div block #{j} of caption file")
            end
            if inferred_lang.eql?(src_lang)
              matching_divs << div 
            end
          elsif lang.eql?(src_lang)
            matching_divs << div
          end
        end
      end

      div_index = 1
      multiple_outputs = matching_divs.size > 1
      matching_divs.each do |div|
        div_lang = div.attributes['lang'].value rescue nil
        file_map = {}
        types.each do |type|
          output_file = File.basename(@cc_file, File.extname(@cc_file))
          # Suffix div index when multiple outputs are created
          output_file << "_#{div_index}" if multiple_outputs
          # Suffix lang to filename if provideds 
          if target_lang && !target_lang.empty?
            output_file << "_#{target_lang}"
          end
          output_file << extension_from_type(type)
          
          out_file = "#{output_dir}#{output_file}"
          if create_file(TYPE_TTML, type, out_file, div_lang)
            file_map[type] = out_file
          else
            raise StandardError.new("Failed to create output file for type #{type}")
          end
        end
        blocks = div.css("p")
        cue_index = 1
        total_blocks = blocks.size
        blocks.each_with_index do |block, index|
          start_time = block.attributes['begin'].value
          end_time = block.attributes['end'].value
          text = block.inner_html.strip.gsub(/(\s){2,}/, '')
          message = ""
          text_blocks = get_block_text(text)
          text_blocks.each do |text_block|
            next if text_block.start_with?('<') || text_block.empty?
            message = text_block
          end
          cue_info = CueInfo.new(callsign)
          cue_info.index = cue_index
          cue_index += 1
          cue_info.message = message
          cue_info.start = start_time
          cue_info.end = end_time
          cue_info.start_time_units = time_details(start_time, callsign)
          cue_info.end_time_units = time_details(end_time, callsign)
          write_cue(cue_info, file_map, index == (total_blocks - 1))
        end
        div_index += 1
      end
    ensure
      xml_file.close if xml_file
    end
  end

  private

  #
  # Method to segregate the data from markups as markups don't need
  # translations.
  # For example, if the cue block is of the form
  # This is a test caption with <span id="1">a test span </span> within a block
  # This method returns
  # ["This is a test caption with ", "<span id=\"1\">", "a test span ", "</span>", " within a block"]
  # as we can infer the markups can be retained as is to avoid translation
  #
  def get_block_text(text)
    data = []
    tag_start = tag_end = false
    str_length = text.size
    text_block = ""
    markup_block = ""
    for i in 0...text.size do
      if text[i] == '<'
        tag_end = false
        tag_start = true
        markup_block << text[i]
        data << text_block
        text_block = ""
        next 
      elsif text[i] == '>'
        tag_end = true
        tag_start = false
        markup_block << text[i]
        data << markup_block
        markup_block = ""
        next
      end
      if tag_start && !tag_end
        markup_block << text[i]
      else
        text_block << text[i]
      end
    end
    unless text_block.empty?
      data << text_block
    end
    data
  end

  # 
  # Method to get a minimal amount of key text that excludes any tags
  # or control information for the engine to meaninfully and 
  # correctly infer the language being referred to in ths TTML
  #
  def get_text(div, num_chars)
    text_sample = ""
    blocks = div.css("p")
    blocks.each do |block|
      # Multiple spaces being stripped off
      text = block.inner_html.strip.gsub(/(\s){2,}/, '')
      # Strip off html tags (if any)
      text = text.gsub(/(<.*?>)/, ' ')
      text_sample << text
      if text_sample.length > (num_chars + 1)
        break
      end
    end
    return text_sample[0, num_chars]
  end
end
