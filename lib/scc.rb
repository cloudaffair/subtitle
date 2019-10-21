require 'aws-sdk-translate'
require 'aws-sdk-comprehend'

class SCC

  def initialize(awskey, awssecret)
    @translate = Aws::Translate::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
    @comp = Aws::Comprehend::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
  end

  def get_text(srt_file, num_chars)
    ccfile = File.open(srt_file, 'r:UTF-8', &:read)
    text_sample = ""
    ccfile.each_line do | line |
      if line =~ /^\d\d:\d\d:\d\d:\d\d\s/
        scc_text_code = line.gsub(/^\d\d:\d\d:\d\d:\d\d\s/, '')
        text_sample << decode(scc_text_code)
        if text_sample.length > (num_chars+1)
          break
        end
      end
    end
    return text_sample[0,num_chars]
  end

  def decode(scc_code_text)
    hex_codes = scc_code_text.gsub(/\s/,'').scan(/.{2}/)
    decoded_text = ""
    skip_next = false
    skip_count = 0
    hex_codes.each do | code |
      if ["94", "91", "92", "97", "15", "16", "10", "13"].include?(code)
        skip_next = true
        skip_count = skip_count +1
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

  def encode(free_text)
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

  def detect_lang(scc_file)
    lang = nil
    begin
      sample_text = get_text(scc_file, 100)
      response = @comp.detect_dominant_language( {
                                                     text: "#{sample_text}"
                                                 })
      lang = response[:languages][0][:language_code] rescue nil
    rescue => error
      puts "Error while detecting the language!!"
    end
    lang
  end
end