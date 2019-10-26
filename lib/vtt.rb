require_relative "../engines/translator"
require_relative "allfather"

#
# Library to handle VTT Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class VTT
  include AllFather

  def initialize(translator)
    @translator = translator
  end

  def translate(srt_file, src_lang, dest_lang, out_file)
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
      next
    end

    if !text_sample.empty?
      trans_resp = @translator.translate(text_sample, src_lang, dest_lang)
      outfile.puts trans_resp
      outfile.puts
      outfile.close
    end
  end

  def infer_language(srt_file)
    lang = nil
    begin
      sample_text = get_text(srt_file, 100)
      lang = @translator.infer_language(sample_text)
    rescue StandardError => e
      puts "Error while detecting the language due to #{e.message}"
    end
    lang
  end

  private 

  def get_text(srt_file, num_chars)
    begin
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
        break if text_sample.length > (num_chars + 1)
        next
      end
    ensure
      ccfile.close rescue nil
    end
    return text_sample[0, num_chars]
  end
end
