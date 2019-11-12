require_relative "engines/translator"
require_relative "utils/common_utils"
require_relative "utils/cue_info"
require_relative "allfather"

#
# Library to handle VTT Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class VTT

  include AllFather
  include CommonUtils

  SUPPORTED_TRANSFORMATIONS = [TYPE_SCC, TYPE_SRT, TYPE_TTML, TYPE_DFXP]

  def initialize(cc_file)
    @cc_file = cc_file
    raise "Invalid VTT file provided" unless is_valid?
  end

  def set_translator(translator)
    super(translator)
    @translator = translator
  end

  def translate(src_lang, dest_lang, out_file)
    super(src_lang, dest_lang, out_file)
    begin
      ccfile = File.open(@cc_file, 'r:UTF-8', &:read)
      outfile = File.open(out_file, "w")
      text_collection = false
      text_sample = ""
      ccfile.each_line do | line |
        if line =~ /^((\d\d:)+\d\d[.,]\d\d\d)\s-->\s((\d\d:)+\d\d[.,]\d\d\d)/
          text_collection = true
          outfile.puts line
        elsif line.strip.empty? && !text_sample.empty?
          json_text = JSON.parse(text_sample) rescue nil
          if json_text.nil?
            trans_resp = @translator.translate(text_sample, src_lang, dest_lang)
            outfile.puts trans_resp
            outfile.puts
          else
            outfile.puts text_sample
            outfile.puts
          end
          text_sample = ""
          text_collection = false
        elsif text_collection
          text_sample << line
        else
          outfile.puts line
        end
      end

      if !text_sample.empty?
        trans_resp = @translator.translate(text_sample, src_lang, dest_lang)
        outfile.puts trans_resp
        outfile.puts
      end
    ensure
      outfile.close
    end
  end

  #
  # Returns the inferred language in an array
  #
  def infer_languages
    lang = nil
    begin
      sample_text = get_text(@cc_file, 100)
      lang = @translator.infer_language(sample_text)
    rescue StandardError => e
      puts "Error while detecting the language due to #{e.message}"
    end
    [lang]
  end

  # 
  # Method to add required set of validations specific to caption type
  #
  def is_valid?
    # Do any VTT specific validations here
    if @cc_file =~ /^.*\.(vtt)$/
      return true
    end
    # TODO: Check if it's required to do a File read to see if the 1st line is WEBVTT
    # to handle cases where invalid file is named with vtt extension
    return false
  end

  def supported_transformations
    return SUPPORTED_TRANSFORMATIONS
  end

  def transform_to(types, src_lang, target_lang, output_dir)
    # Let's start off with some validations
    super(types, src_lang, target_lang, output_dir)

    # Suffix output dir with File seperator
    output_dir = "#{output_dir}#{File::Separator}" unless output_dir.end_with?(File::Separator)
    
    # Prepare the output files for each type
    file_map = {}
    types.each do |type|
      output_file = File.basename(@cc_file, File.extname(@cc_file)) + extension_from_type(type)
      out_file = "#{output_dir}#{output_file}"
      if create_file(TYPE_VTT, type, out_file, target_lang)
        file_map[type] = out_file
      else
        raise StandardError.new("Failed to create output file for type #{type}")
      end
    end

    # Read the file and prepare the cue model
    cue_info = nil
    ccfile = File.open(@cc_file, 'r:UTF-8', &:read)
    message = ""
    collect_msg = false
    cue_index = 1
    ccfile.each_line do | line |
      if line.strip.empty?
        collect_msg = false
        next 
      end
      time_points = line.scan(/^((\d\d:)+\d\d[.,]\d\d\d)\s-->\s((\d\d:)+\d\d[.,]\d\d\d)/)
      if time_points.empty?
        if collect_msg
          message << line
        end
      else
        collect_msg = false
        unless message.empty?
          cue_info.message = message 
          write_cue(cue_info, file_map)
          message = ""
          cue_index += 1
        end
        # This is a cue point. Fetch timestamps
        cue_info = CueInfo.new(AllFather::TYPE_VTT)
        cue_info.index = cue_index
        cue_info.start = time_points[0][0]
        cue_info.end = time_points[0][2]
        start_units = time_details(cue_info.start, TYPE_VTT)
        end_units = time_details(cue_info.end, TYPE_VTT)
        cue_info.start_time_units = start_units
        cue_info.end_time_units = end_units
        collect_msg = true
      end
    end
    cue_info.message = message unless message.empty?
    write_cue(cue_info, file_map, true)
  end

  private 

  # 
  # Method to get a minimal amount of key text that excludes any tags
  # or control information for the engine to meaninfully and 
  # correctly infer the language being referred to in ths VTT
  #
  def get_text(vtt_file, num_chars)
    begin
      ccfile = File.open(vtt_file, 'r:UTF-8', &:read)
      text_collection = false
      text_sample = ""
      ccfile.each_line do |line|
        if line =~ /^((\d\d:)+\d\d[.,]\d\d\d)\s-->\s((\d\d:)+\d\d[.,]\d\d\d)/
          text_collection = true
        elsif line.strip.empty?
          text_collection = false
        elsif text_collection && text_sample.length < (num_chars + 1)
          text_sample << line
        end
        break if text_sample.length > (num_chars + 1)
      end
    ensure
      ccfile.close rescue nil
    end
    return text_sample[0, num_chars]
  end
end
