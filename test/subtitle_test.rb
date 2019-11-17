require "optimist"
require "subtitle"


SUB_COMMANDS = %w(detectlang translate transform)
global_opts = Optimist::options do
  banner "Subtitle Utility for lingual detection, translation from one language to another & transform from one format to another"
  opt :access_key_id, "AWS Key", :type => :string, :short => "k"
  opt :secret_access_key, "AWS Secret", :type => :string, :short => "s"
  opt :profile, "AWS Profile", :type => :string, :short => "p"
  #opt :api_key, "Google Translate API Key", :type => :string, :short => "a"
  opt :cc_file, "Closed caption File", :type => :string, :short => "i", :required => true
  opt :dest_lang, "Language code to translate", :type => :string, :short => "d"
  opt :src_lang, "Source language", :type => :string, :short => "l"
  opt :outfile, "Destination file / directory", :type => :string, :short => "f"
  opt :force_detect, "Will try to infer the language even if language is provided. By default false if not provided", :type => :boolean, :short => "w", :default => false
  opt :types, "comma seperated lowercase formats to convert to. valid values are srt, scc, vtt, ttml and dfxp", :type=>:string, :short => "t"
end
Optimist::die :cc_file, "File Does not Exist" unless File.exist?(global_opts[:cc_file]) if global_opts[:cc_file]
cmd = ARGV.shift # get the subcommand
cmd_opts = case cmd
              when "detectlang" # parse detectlang options
                subtitle = Subtitle.new(global_opts[:cc_file])
                puts subtitle.detect_language(global_opts)
              when "translate"  # parse translate options
                if global_opts[:dest_lang].nil?
                  puts "Need to provide destination language code option[-d] missing"
                  exit 1
                end
                subtitle = Subtitle.new(global_opts[:cc_file])
                subtitle.translate(global_opts[:dest_lang], global_opts[:src_lang], global_opts[:outfile], global_opts)
              when "transform" # parse transform options
                if global_opts[:outfile].nil? || global_opts[:types].nil?
                  puts "Need to provide destination location using option[-f] & types using option[-t]"
                  exit 1
                end
                subtitle = Subtitle.new(global_opts[:cc_file])
                type_values = global_opts[:types]
                types = type_values.split(",")
                # strip any leading and trailing spaces
                types = types.map {|x| x.strip}
                subtitle.transform(types, global_opts, global_opts[:dest_lang],  global_opts[:src_lang])
              else
                Optimist::die "unknown subcommand #{cmd.inspect}"
           end

