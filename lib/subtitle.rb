require "subtitle/version"
require "subtitle/srt"

module Subtitle
  class Error < StandardError; end
  # Your code goes here...
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

SUB_COMMANDS = %w(detectlang translate)
global_opts = Optimist::options do
  banner "Subtitle Utility for lingual detection and translation"
  opt :aws_key, "AWS Key", :type => :string, :short => "k", :required => true
  opt :aws_secret, "AWS Secret", :type => :string, :short => "s", :required => true
  opt :cc_file, "Closed caption File", :type => :string, :short => "i", :required => true
  opt :dest_lang, "Language code to translate", :type => :string, :short => "d"
  opt :src_lang, "Source language", :type => :string, :short => "l"
  opt :outfile, "Destination file", :type => :string, :short => "f"
end
Optimist::die :cc_file, "File Does not Exist" unless File.exist?(global_opts[:cc_file]) if global_opts[:cc_file]
cmd = ARGV.shift # get the subcommand
cmd_opts = case cmd
             when "detectlang" # parse detectlang options
               subtitle = Subtitle.new(global_opts[:aws_key], global_opts[:aws_secret], global_opts[:cc_file])
               puts subtitle.detect_language
             when "translate"  # parse translate options
               if global_opts[:dest_lang].nil?
                 puts "Need to provide destination language code option[-f] missing"
                 exit
               end
               subtitle = Subtitle.new(global_opts[:aws_key], global_opts[:aws_secret], global_opts[:cc_file])
               puts subtitle.translate_cc(global_opts[:dest_lang],global_opts[:src_lang],global_opts[:outfile])
             else
               Optimist::die "unknown subcommand #{cmd.inspect}"
           end


