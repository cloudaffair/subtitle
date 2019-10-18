require "srt"

class Subtitle
  def initialize(awskey, awssecret, ccfile)
    if awskey.nil? || awssecret.nil? || ccfile.nil?
      raise "Invalid Arguments, please check"
    end
    @ccfile = ccfile
    unless file_valid
      raise "Incorrect File extension"
    end
    begin
      @srt_parser = SRT.new(awskey, awssecret)
    rescue
      raise "Could not initialize Parser!!. Check the Keys supplied."
    end
  end

  def detect_language
    detected_lang = @srt_parser.detect_lang(@ccfile)
    detected_lang
  end

  def translate_cc( dest_lang, src_lang = nil, outfile = nil)
    if outfile.nil?
      outfile = "#{@ccfile}_#{dest_lang}"
    end
    if src_lang.nil?
      src_lang = detect_language
      raise "could not detect Source Language!!"  if src_lang.nil?
    end
    @srt_parser.translate_text(@ccfile, src_lang, dest_lang, outfile)
    outfile
  end

  def file_valid
    valid = false
    if @ccfile =~ /^.*\.(srt|vtt)$/
      valid = true
    end
    valid
  end
end