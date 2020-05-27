require_relative "srt"
require_relative "vtt"
require_relative "scc"
require_relative "ttml"
require_relative "dfxp"
require_relative "transcribehelper"
require_relative "allfather"
require_relative "engines/translator"
require_relative "engines/aws"
require "uri"


#
# Facade that wraps all the complexities surrounding which translation
# engine to use or which caption instances to be instantiated.
# 
class Subtitle

  TYPE_MAP = {"scc" => AllFather::TYPE_SCC, "srt" => AllFather::TYPE_SRT, "vtt" => AllFather::TYPE_VTT, 
              "ttml" => AllFather::TYPE_TTML, "dfxp" => AllFather::TYPE_DFXP}
  ENCODE_UNSAFE = ['"','<','>','{','}','|','\\','^','~','[',']','`',' ','#']
  ENCODE_RESERVED = [';','$','?','@','=',':','/','&','+',',']

  def initialize(file, options = nil)
    # Infer the caption handler from the extension
    @cc_file = file
    raise "Input caption not provided. Please provide the same in :cc_file option" if @cc_file.nil?
    initialize_handler(options) unless options.nil?
  end

  def detect_language(options = nil)
    initialize_handler(options) if @handler.nil?
    @handler.infer_languages
  end

  def translate(dest_lang, src_lang = nil, outfile = nil, options = nil)
    initialize_handler(options) if @handler.nil?
    if outfile.nil?
      outfile = "#{@cc_file}_#{dest_lang}"
    end
    if src_lang.nil?
      src_lang = detect_language[0] rescue nil
      raise "Could not detect Source Language!!" if src_lang.nil?
    end
    @handler.translate(src_lang, dest_lang, outfile)
    outfile
  end

  def transform(types, options = nil, target_lang = nil, src_lang = nil)
    # A quick validation & translation to expected arguments
    vals = []
    invalid_vals = []
    types.each do |type|
      type_val = TYPE_MAP[type]
      if type_val.nil?
        invalid_vals << type
        next
      end
      vals << type_val
    end
    unless invalid_vals.empty?
      raise "Invalid types #{invalid_vals} provided"
    end
    # Translator not required if target_lang is nil
    if @handler.nil?
      if target_lang.nil? && src_lang.nil?
        @handler = get_caption_handler(options, nil) 
      else
        initialize_handler(options)
      end
    end
    output_dir = options[:outfile]
    @handler.transform_to(vals, src_lang, target_lang, output_dir)
  end

  def generate_srt(outfile)
    srt_helper = TranscribeHelper.new
    srt_helper.parse_file(@cc_file, outfile)
  end

  def transcribe(options)
    # From here call the "aws.rb"
    # Get the transcribe output json file 
    # Pass it to the generate_srt

    aws = AwsEngine.new(options)
    outfile = options[:outfile]
    bucket = options[:bucket]
    audio_lang = options[:audio_lang]
    video_file = options[:video_file]
    transcribe_json_file = nil
    isurl = isURL?(video_file)
    if(isurl == true)
      output = aws.transcribe_uri(video_file, audio_lang, bucket)
    else
      output = aws.transcribe_file(video_file, audio_lang, bucket)
    end
    if output["status"].eql?("FAILED")
      failure_reason = output["failure_reason"]
      #return "AWS Transcribe failed #{failure_reason}"
      raise StandardError.new(failure_reason)
    end
    transcribe_json_file = output["temp_json_output"]
    srt_helper = TranscribeHelper.new
    srt_helper.parse_file(transcribe_json_file, outfile)
    File.delete(transcribe_json_file) if File.exist?(transcribe_json_file)
    aws.delete_temp_transcribe_file(bucket, output)
  end

  def isURL?(url_string)
    begin
      url = parseURI(url_string) rescue nil
      case (url.scheme rescue nil)
      when "http", "https", "ftp"
        if url.host.nil?
          return false
        else
          return true
        end
      end
    rescue StandardError => e
      puts "Error parsing URI (#{url_string}). Error: #{e}"
    end
    return false
  end

  def parseURI(uri_string)
    encoded_uri = URI.encode(URI.decode(uri_string)) #decode first in case uri is already partially encoded
    safe_uri = URI.encode(encoded_uri, ENCODE_UNSAFE.join)
    uri = URI.parse(safe_uri)
    #This is probably not a remote uri if there is no scheme. Should be a local file
    #URI encode reserved characters to ensure that the filename is not modified of during parsing
    uri = URI.parse(URI.encode(safe_uri, ENCODE_RESERVED.join)) if !uri.scheme 
    uri
  end

  def type
    type = nil
    ccfile = File.open(@cc_file, 'r:UTF-8', &:read)
    ccfile.each_line do | line |
      if line =~ /^(\d\d:)\d\d:\d\d[,]\d\d\d.*-->.*(\d\d:)\d\d:\d\d[,]\d\d\d/
        type = "srt"
      elsif line =~ /^((\d\d:)+\d\d[.,]\d\d\d)\s-->\s((\d\d:)+\d\d[.,]\d\d\d)|(^WEBVTT$)/
        type = "vtt"
      elsif line =~ /(^\d\d:\d\d:\d\d:\d\d\t(([0-9a-fA-F]{4})\s)*)+|(^Scenarist_SCC V(\d.\d)$)/
        type = "scc"
      end
    end
    unless type
      doc = File.open(@cc_file) { |f| Nokogiri::XML(f) }
      namespace = doc.namespaces["xmlns"]
      if doc.errors.empty?
        if doc.xpath('/*').first.name == 'tt' && !doc.css('/tt/head').nil? && !doc.css('/tt/body').nil?
          if namespace =~ /\/ttaf1/
            type = "dfxp"
          elsif namespace =~ /\/ttml/
            type = "ttml"
          end
        end
      end
    end
    type
  end

  private

  def initialize_handler(options)
    translator = get_translator(options)
    @handler = get_caption_handler(options, translator)
  end

  def get_translator(options)
    translator = nil
    # Try to infer the engine based on the passed options
    engine = options[:engine]
    unless engine
      engine_props = Translator::ENGINE_KEYS
      engine_props.each do |k, values|
        original_size = values.size 
        diff = values - options.keys
        if diff.size < original_size
          # We have some keys for this engine in options
          engine = k
          break
        end
      end
    end
    case engine 
    when Translator::ENGINE_AWS
      translator = AwsEngine.new(options)
    when Translator::ENGINE_GCP
      raise "GCP is yet to be implemented"
    else
      raise "Unable to infer the Translation Engine. Options missing key credential params"
    end
    translator
  end

  def get_caption_handler(options, translator)
    caption_file = options[:cc_file]
    extension = File.extname(caption_file)
    extension = ".#{type}" if extension.nil?
    unless AllFather::VALID_FILES.include?(extension)
      raise "Caption support for #{caption_file} of type #{extension} is not supported yet" 
    end
    handler = nil
    case extension.downcase
    when ".scc"
      handler = SCC.new(caption_file)
    when ".srt"
      handler = SRT.new(caption_file)
    when ".vtt"
      handler = VTT.new(caption_file)
    when ".ttml"
      handler = TTML.new(caption_file, options)
    when ".dfxp"
      handler = DFXP.new(caption_file, options)
    when ".json"
      handler = nil
    else
      raise "Cannot handle file type .#{extension}"
    end
    handler.set_translator(translator) if handler
    handler
  end
end
