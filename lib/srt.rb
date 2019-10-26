require_relative "../engines/translator"
require_relative "allfather"

#
# Library to handle SRT Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class SRT

  include AllFather

  def initialize(cc_file, translator)
    @cc_file = cc_file
    @translator = translator
    raise "Invalid SRT file provided" unless is_valid?
  end

  def is_valid?
    # Do any VTT specific validations here
    if @cc_file =~ /^.*\.(srt)$/
      return true
    end
    return false
  end

  def translate(src_lang, dest_lang, out_file)
    super(src_lang, dest_lang, out_file)
    begin
      ccfile = File.open(@cc_file, 'r:UTF-8', &:read)
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
      end

      if !text_sample.empty?
        trans_resp = @translator.translate(text_sample, src_lang, dest_lang)
        outfile.puts trans_resp
        outfile.puts
      end
    ensure
      ccfile.close rescue nil
      outfile.close
    end
  end

  def infer_language
    lang = nil
    begin
      sample_text = get_text(@cc_file, 100)
      lang = @translator.infer_language(sample_text)
    rescue StandardError => e
      puts "Error while detecting the language due to #{e.message}"
    end
    lang
  end

  private 

  # 
  # Method to get a minimal amount of key text that excludes any tags
  # or control information for the engine to meaninfully and 
  # correctly infer the language being referred to in ths VTT
  #
  def get_text(srt_file, num_chars)
    begin
      ccfile = File.open(srt_file, 'r:UTF-8', &:read)
      text_collection = false
      text_sample = ""
      ccfile.each_line do |line|
        if line =~ /^(\d\d:)\d\d:\d\d[,.]\d\d\d.*-->.*(\d\d:)\d\d:\d\d[,.]\d\d\d/
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