require_relative "engines/translator"
require_relative "allfather"
require_relative "ttml"

#
# Library to handle DFXP Files
#
# Uses the translator available to do the necessary language operations
# as defined by the AllFather
#
class DFXP < TTML

	def initialize(cc_file, translator, opts={})
    @cc_file = cc_file
    @translator = translator
    @force_detect = opts[:force_detect] || false
    raise "Invalid TTML file provided" unless is_valid?
  end

  def is_valid?
    # Do any VTT specific validations here
    if @cc_file =~ /^.*\.(dfxp)$/
      return true
    end
    # TODO: Check if it's required to do a File read to see if this
    # a well-formed XML. Another is to see if lang is available in each div
    return false
  end
  
end