require_relative "engines/translator"
require_relative "utils/common_utils"
require_relative "utils/cue_info"
require_relative "allfather"

#
# Library to handle SCC Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class SCC

  include AllFather
  include CommonUtils

  SUPPORTED_TRANSFORMATIONS = [TYPE_SRT, TYPE_VTT, TYPE_TTML, TYPE_DFXP]

  def initialize(cc_file)
    @cc_file = cc_file
    raise "Invalid SCC file provided" unless is_valid?
  end

  def is_valid?
    # Do any SCC specific validations here
    if @cc_file =~ /^.*\.(scc)$/
      return true
    end
    return false
  end

  def set_translator(translator)
    @translator = translator
  end

  def infer_languages
    lang = nil
    begin
      sample_text = get_text(@cc_file, 100)
      lang = @translator.infer_language(sample_text)
    rescue StandardError => e
      puts "Error while detecting the language due to #{e.message}"
    end
    lang
  end

  def translate(src_lang, dest_lang, out_file)
    raise "Not Implemented. Class #{self.class.name} doesn't implement translate yet !!"
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
      if create_file(type, out_file, target_lang)
        file_map[type] = out_file
      else
        raise StandardError.new("Failed to create output file for type #{type}")
      end
    end

    # Read the file and prepare the cue model
    prev_cue_info = cur_cue_info = nil
    ccfile = File.open(@cc_file, 'r:UTF-8', &:read)
    cue_index = 1
    ccfile.each_line do | line |
      time_point = line.scan(/(^\d\d:\d\d:\d\d:\d\d\s)(.*)/)
      unless time_point.empty?
        scc_text_code = time_point[0][1].strip
        message = decode(scc_text_code)
        # Replace \u0000 with empty as this causes the ttml / dfxp outputs
        # to treat them as end and terminates the xml the moment this is encountered
        # https://github.com/sparklemotion/nokogiri/issues/1535
        message = message.gsub(/\u0000/, '')
        if prev_cue_info.nil?
          prev_cue_info = CueInfo.new(TYPE_SCC)
          prev_cue_info.index = cue_index
          prev_cue_info.message = message
          prev_cue_info.start = time_point[0][0].strip
        else
          cur_cue_info = CueInfo.new(TYPE_SCC)
          cur_cue_info.index = cue_index
          cur_cue_info.message = message
          cur_cue_info.start = time_point[0][0].strip
          # Set the previous cue info's end time to current cue's start time
          # TODO: Need to see if we need to reduce alteast 1 fps or 1s
          prev_cue_info.end = cur_cue_info.start
          prev_cue_info.start_time_units = time_details(prev_cue_info.start, TYPE_SCC)
          prev_cue_info.end_time_units = time_details(prev_cue_info.end, TYPE_SCC)
          write_cue(prev_cue_info, file_map)
          prev_cue_info = cur_cue_info
        end
        cue_index += 1
      end
    end
    # we need to set some end time, but don't know the same !!
    # for now setting the start time itself
    cur_cue_info.end = cur_cue_info.start 
    cur_cue_info.start_time_units = time_details(cur_cue_info.start, TYPE_SCC)
    cur_cue_info.end_time_units = time_details(cur_cue_info.end, TYPE_SCC)
    write_cue(cur_cue_info, file_map, true)
  end

  private

  def get_text(srt_file, num_chars)
    ccfile = File.open(srt_file, 'r:UTF-8', &:read)
    text_sample = ""
    ccfile.each_line do | line |
      if line =~ /^\d\d:\d\d:\d\d:\d\d\s/
        scc_text_code = line.gsub(/^\d\d:\d\d:\d\d:\d\d\s/, '')
        text_sample << decode(scc_text_code)
        if text_sample.length > (num_chars + 1)
          break
        end
      end
    end
    return text_sample[0, num_chars]
  end

  def decode(scc_code_text)
    hex_codes = scc_code_text.gsub(/\s/,'').scan(/.{2}/)
    decoded_text = ""
    skip_next = false
    skip_count = 0
    hex_codes.each do | code |
      if ["94", "91", "92", "97", "15", "16", "10", "13"].include?(code)
        skip_next = true
        skip_count = skip_count + 1
        next
      end
      if skip_count == 1 && skip_next
        skip_next = false
        skip_count = 0
        next
      end
      dec_val = code.to_i(16) & 0x7F
      decoded_text << dec_val.chr
    end
    decoded_text
  end
end
