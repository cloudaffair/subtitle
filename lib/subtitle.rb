require_relative "srt"
require_relative "vtt"
require_relative "scc"
require_relative "ttml"
require_relative "dfxp"
require_relative "allfather"
require_relative "engines/translator"
require_relative "engines/aws"


class Subtitle
  def initialize(file, options = nil)
    # Infer the caption handler from the extension
    @cc_file = file
    raise "Input caption not provided. Please provide the same in :cc_file option" if @cc_file.nil?
    initialize_handler(options) unless  options.nil?
  end



  def detect_language(options = nil)
    initialize_handler(options) if @handler.nil?
    @handler.infer_languages
  end

  def translate(dest_lang, src_lang = nil, outfile = nil, options = nil)
    initialize_handler(options) unless  @handler.nil?
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
    extension = ".#{type}" unless extension.nil?
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
      handler = TTML.new(caption_file)
    when ".dfxp"
      handler = DFXP.new(caption_file)
    else
      raise "Cannot handle file type .#{extension}"
    end
    handler.set_translator(translator)
    handler
  end
end
