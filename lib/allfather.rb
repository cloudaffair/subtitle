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
  # Method to translate the caption from one language to another
  #
  # :args: src_lang, target_lang, output_file
  #
  # * +input_caption+   - A Valid input caption file. Refer to #is_valid?
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
end
