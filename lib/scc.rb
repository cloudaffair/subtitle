require_relative "engines/translator"
require_relative "allfather"

#
# Library to handle SCC Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class SCC

  include AllFather

  def initialize(cc_file, translator)
    @cc_file = cc_file
    @translator = translator
    raise "Invalid SCC file provided" unless is_valid?
  end

  def is_valid?
    # Do any SCC specific validations here
    if @cc_file =~ /^.*\.(scc)$/
      return true
    end
    return false
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

  def self.encode(free_text)
    encoded_str = ""
    count = 0
    free_text.each_byte do |char|
      count += 1
      binval = char.to_s(2).count("1") % 2 == 0 ? (char.to_i | 128 ).to_s(2) : char.to_s(2)
      encode_char = binval.to_i(2).to_s(16)
      if ((count > 0) && (count % 2 == 0))
        encoded_str << encode_char << " "
      else
        encoded_str << encode_char
      end
    end
    encoded_str
  end
end
