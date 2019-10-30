require_relative "engines/translator"
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

  def initialize(cc_file, translator, opts={})
    @cc_file = cc_file
    @translator = translator
    @force_detect = opts[:force_detect] || false
    raise "Invalid TTML file provided" unless is_valid?
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

  def infer_languages
    lang = []
    begin
      xml_file = File.open(@cc_file)
      xml_doc  = Nokogiri::XML(xml_file)
      div_objects = xml_doc.css("/tt/body/div")
      div_objects.each_with_index do |div, index|
        # By default, return the lang if specified in the div and 
        # force detect is false
        inferred_lang = div.attributes['lang'].value rescue nil
        if inferred_lang.nil?
          # If lang is not provided in the caption, then override
          # force detect for inferrence
          @force_detect = true
        end
        if @force_detect
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
    #super(src_lang, dest_lang, out_file)
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
