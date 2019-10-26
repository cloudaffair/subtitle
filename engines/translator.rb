# 
# A Module that kind of acts as an interface where the methods
# expected out of each vendor is encapsulated into
#
# To use for a new vendor, simply include this module and provide
# caption specific implementations
#
module Translator
  #
  # This exception shall be raised when we fail to initialize an
  # engine for the purposes of language detection / translation
  #
  # ==== Example
  # * When credentials are not passed
  #
  class EngineInitializationException < StandardError; end

  #
  # Method to infer the language by inspecting the text
  # passed as argument
  #
  # :args: text
  #
  # * +text+ - String whose language needs to be inferred
  #
  # ==== Returns
  #
  # * The ISO 639-1 Letter Language code
  # 
  def infer_language(text)
    raise "Not Implemented. Class #{self.class.name} doesn't implement infer_language"
  end

  #
  # Method to translate from given language to another
  #
  # :args: input_text, src_lang, target_lang, output_file
  #
  # * +input_text+      - Text which needs to be translated
  # * +src_lang+        - can be inferred using #infer_language method
  # * +target_lang+     - Target 2 letter ISO language code to which the source needs to be translated in to.
  # 
  def translate(input_text, src_lang, target_lang)
    raise "Not Implemented. Class #{self.class.name} doesn't implement translate"
  end
end