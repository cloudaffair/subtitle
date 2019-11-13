require_relative "engines/translator"
require_relative "allfather"
require_relative "ttml"

#
# Library to handle DFXP Files
#
# Extends the TTML Class as except for namespace differences there isn't
# much to call between ttml and dfxp
#
class DFXP < TTML

  SUPPORTED_TRANSFORMATIONS = [TYPE_SCC, TYPE_SRT, TYPE_VTT, TYPE_TTML]

	def initialize(cc_file, opts=nil)
    @cc_file = cc_file
    @force_detect = opts[:force_detect] || false
    raise "Invalid DFXP file provided" unless is_valid?
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

  def callsign
    TYPE_DFXP
  end

  def supported_transformations
    return SUPPORTED_TRANSFORMATIONS
  end  
end