require "optimist"
require "subtitle"


SUB_COMMANDS = %w(detectlang translate)
global_opts = Optimist::options do
  banner "Subtitle Utility for lingual detection and translation"
  opt :access_key_id, "AWS Key", :type => :string, :short => "k"
  opt :secret_access_key, "AWS Secret", :type => :string, :short => "s"
  opt :profile, "AWS Profile", :type => :string, :short => "p"
  opt :api_key, "Google Translate API Key", :type => :string, :short => "a"
  opt :cc_file, "Closed caption File", :type => :string, :short => "i", :required => true
  opt :dest_lang, "Language code to translate", :type => :string, :short => "d"
  opt :src_lang, "Source language", :type => :string, :short => "l"
  opt :outfile, "Destination file", :type => :string, :short => "f"
  opt :force_detect, "Will try to infer the language even if language is provided. By default false if not provided", :type => :boolean, :short => "w", :default => false
end
Optimist::die :cc_file, "File Does not Exist" unless File.exist?(global_opts[:cc_file]) if global_opts[:cc_file]
cmd = ARGV.shift # get the subcommand
cmd_opts = case cmd
             when "detectlang" # parse detectlang options
               subtitle = Subtitle.new(global_opts)
               puts subtitle.detect_language
             when "translate"  # parse translate options
               if global_opts[:dest_lang].nil?
                 puts "Need to provide destination language code option[-f] missing"
                 exit 1
               end
               subtitle = Subtitle.new(global_opts)
               puts subtitle.translate(global_opts[:dest_lang], global_opts[:src_lang], global_opts[:outfile])
             else
               Optimist::die "unknown subcommand #{cmd.inspect}"
           end


