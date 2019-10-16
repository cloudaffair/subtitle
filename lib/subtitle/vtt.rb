require 'aws-sdk-translate'
require 'aws-sdk-comprehend'

class VTT
  def initialize(awskey, awssecret)
    @translate = Aws::Translate::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
    @comp = Aws::Comprehend::Client.new(:access_key_id => "#{awskey}", :secret_access_key => "#{awssecret}")
  end

  def translate_text(srt_file, src_lang, dest_lang, out_file)
    ccfile = File.open(srt_file, 'r:UTF-8', &:read)
    outfile = File.open(out_file, "w")
    text_collection = false
    text_sample = ""
    ccfile.each_line do | line |
      if line =~ /^(\d\d:)\d\d:\d\d[,.]\d\d\d.*-->.*(\d\d:)\d\d:\d\d[,.]\d\d\d/
        text_collection = true
        outfile.puts line
      elsif line.strip.empty? && !text_sample.empty?
        json_text = JSON.parse(text_sample) rescue nil
        if json_text.nil?
          trans_resp = @translate.translate_text({ :text => "#{text_sample}" , :source_language_code => "#{src_lang}", :target_language_code => "#{dest_lang}"})
          outfile.puts trans_resp.translated_text
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
      next
    end

    if !text_sample.empty?
      trans_resp = @translate.translate_text({ :text => "#{text_sample}" , :source_language_code => "#{src_lang}", :target_language_code => "#{dest_lang}"})
      outfile.puts trans_resp.translated_text
      outfile.puts
      outfile.close
    end
  end


  def get_text(srt_file, num_chars)
    ccfile = File.open(srt_file, 'r:UTF-8', &:read)
    text_collection = false
    text_sample = ""
    ccfile.each_line do | line |
      line = line
      if line =~ /^(\d\d:)\d\d:\d\d[,.]\d\d\d.*-->.*(\d\d:)\d\d:\d\d[,.]\d\d\d/
        text_collection = true
      elsif line.strip.empty?
        text_collection = false
      elsif text_collection && text_sample.length < (num_chars+1)
        text_sample << line
      end
      break if text_sample.length > (num_chars+1)
      next
    end
    return text_sample[0,num_chars]
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
