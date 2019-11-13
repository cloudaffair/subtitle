require 'fileutils'
require_relative "engines/translator"

# 
# A Module that kind of acts as an interface where the generic methods
# that applies to each caption type can be defined
#
# To use for a new caption type, simply include this module and provide
# caption specific implementations
#
module AllFather
  
  # 
  # Valid file extensions that we support; Keep expanding as we grow
  #
  VALID_FILES = [".scc", ".srt", ".vtt", ".ttml", ".dfxp"]

  #
  # Caption type constants
  #
  TYPE_SCC  = 1
  TYPE_SRT  = 2
  TYPE_VTT  = 3
  TYPE_TTML = 4
  TYPE_DFXP = 5

  # 
  # Generic exception class that is raised for validation errors
  #
  class InvalidInputException < StandardError; end

  #
  # Lang inference failure exception
  #
  class LangDetectionFailureException < StandardError; end

  #
  # Method to do basic validations like is this a valid file to even
  # accept for any future transactions 
  #
  # ==== Returns:
  # true if the file is valid and false otherwise
  #
  def is_valid?
    raise "Not Implemented. Class #{self.class.name} doesn't implement is_valid?"
  end

  #
  # Method to infer the language(s) of the caption by inspecting the file
  # depending on the type of the caption file
  #
  # ==== Returns
  #
  # * The ISO 639-1 Letter Language codes
  # 
  def infer_languages
    raise "Not Implemented. Class #{self.class.name} doesn't implement infer_languages"
  end


  # 
  # Method to set a translation engine
  #
  # * +translator+  - Instance of translation engine. Refer to `engines/aws` for example
  #
  # ==== Raises
  # * `InvalidInputException` when the argument `translator` is not an instance of Translator class
  #
  def set_translator(translator)
    if translator && !(translator.is_a? Translator)
      raise InvalidInputException.new("Argument is not an instance of Translator")
    end
  end

  #
  # Method to translate the caption from one language to another
  #
  # * +src_lang+        - can be inferred using #infer_language method
  # * +target_lang+     - Target 2 letter ISO language code to which the source needs to be translated in to.
  # * +output_file+     - Output file. Can be a fully qualified path or just file name
  #
  # ==== Raises
  # 
  # InvalidInputException shall be raised if
  # 1. The input file doesn't exist or is unreadable or is invalid caption
  # 2. The output file can't be written
  # 3. The target_lang is not a valid ISO 639-1 Letter Language code
  #
  def translate(src_lang, target_lang, output_file)
    # Check if a non empty output file is present and error out to avoid
    # the danger or overwriting some important file !!
    if File.exists?(output_file) && File.size(output_file) > 0
      raise InvalidInputException.new("Output file #{output_file} is not empty.")
    else
      # Just open the file in writable mode and close it just to ensure that
      # we can write the output file
      File.open(output_file, "w") {|f|
      }
    end
    # Check if the file is writable ?
    unless File.writable?(output_file)
      raise InvalidInputException.new("Output file #{output_file} not writable.")
    end
    # Further checks can be done only in caption specific implementations
    # or translation engine specific implementation
  end

  #
  # Method to convert from one caption type to other types. If the src_lang is not provided
  # then all source languages will be converted to target types. For example, if a ttml file
  # has "en" and "es" and target_type is vtt and no src_lang is provided 2 vtt files would be
  # created one per language in the source. if a target_lang is provided then one of the lang
  # from source would be picked for creating the output file with target_lang
  #
  # If no target_lang is provided, no translations are applied. output_file is created using
  # without any need for any language translation services. Hence doesn't incur any cost !!
  #
  # * +types+           - An array of Valid input caption type(s). Refer to `#CaptionType`
  # * +src_lang+        - can be inferred using #infer_language method
  # * +target_lang+     - Target 2 letter ISO language code to which the source needs to be translated in to.
  # * +output_dir+      - Output Directory. Generated files would be dumped here
  #
  # ==== Raises
  # 
  # InvalidInputException shall be raised if
  # 1. The input file doesn't exist or is unreadable or is invalid caption
  # 2. The output dir doesn't exist 
  # 3. Invalid lang codes for a given caption type
  # 4. Unsupported type to which conversion is requested for
  #
  def transform_to(types, src_lang, target_lang, output_dir)
    if (types - supported_transformations).size != 0
      raise InvalidInputException.new("Unknown types provided for conversion in input #{types}")
    end
    unless File.directory?(output_dir)
      FileUtils.mkdir_p(output_dir)
    end
    # Basic validations
    if types.include?(TYPE_SCC)
      if target_lang && !target_lang.eql?("en")
        raise InvalidInputException.new("SCC can be generated only in en. #{target_lang} is unsupported")
      end
    end
    if target_lang && !target_lang.empty?
      raise InvalidInputException.new("Translation to other language as part of transform is yet to be implemented")
    end
  end

  # 
  # Method to report on the supported transformations. Each implementor is free to return
  # the types to which it can convert itself to
  #
  # ==== Returns 
  # 
  # * An array of one or more types defined as +TYPE_+ constants here 
  #
  def supported_transformations
    raise "Not Implemented. Class #{self.class.name} doesn't implement supported_transformations"
  end

  #
  # While the logic of abstracting stuff to callers has it's benefits, sometimes it's required
  # to identify which instance are we specifically operate on. This method returns the instance
  # currently being operated on and returns one of the +TYPE_+ constants defined here
  # Implement this unless and absolutely it's necessary and there is no other easy way to do things 
  #
  # ===== Returns
  #
  # * the call sign of the instance
  #
  def callsign
    raise "Not Implemented. Class #{self.class.name} doesn't implement callsign"
  end
end
