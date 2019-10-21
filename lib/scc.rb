require 'aws-sdk-translate'
require 'aws-sdk-comprehend'

class SCC

=begin
  def initialize(awskey, awssecret)
    @translate = Aws::Translate::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
    @comp = Aws::Comprehend::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
  end
=end
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

  def encode (plain_text)
    encoded_text = ""
    two_bytes_str = ""
    plain_text.each_char do | char |
      if char.ord.to_s(2).count("1") % 2 == 0
        two_bytes_str << char.ord.to_s(16)
      else
        puts "test #{(char.to_i(16) | 0x7F  )}"
        two_bytes_str << (char.to_i(16) | 0x7F  ).to_s(16)
      end
      if two_bytes_str.length == 4
        encoded_text << two_bytes_str+" "
        two_bytes_str = ""
      end

    end
    puts encoded_text
  end
  def detect_lang(srt_file)
    lang = nil
    begin
      sample_text = get_text(srt_file, 100)
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

scc = SCC.new
#"InqScribe works on Mac or Windows."
scc.encode("InqScribe works on Mac or Windows.")
#
#puts scc.decode("94ae 94ae 9420 9420 9452 9452 9723 9723 496e f1d3 e3f2 e962 e520 f7ef f26b 7320 ef6e 94f4 94f4 cd61 e320 eff2 2057 e96e 64ef f773 ae80 942f 942f")
#c9ee f1d3 e3f2 e9e2 e5a0 f7ef f2eb f3a0 efee a0cd e1e3 a0ef f2a0 d7e9 eee4 eff7 f3ae
#scc.encode("InqScribe works on Mac or Windows.")