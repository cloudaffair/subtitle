# Subtitle

[![Gem Version](https://badge.fury.io/rb/subtitle.svg)](https://badge.fury.io/rb/subtitle)
[![Build Status](https://travis-ci.org/cloudaffair/subtitle.svg?branch=master)](https://travis-ci.org/cloudaffair/subtitle)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](pgmaheshwaran@gmail.com)

Welcome to `subtitle` gem!. Following functionalities are provided using AWS services.

* Detect the Language code for the given Subtitle file
* Translates the given subtitle file to required suggested language.
* Auto detects the type of subtitle in case no extension to the file provided.
* Convert from one caption format to another. Refer below for supported formats

Supports following subtitle files

* SubRip (.srt)
* WebVTT (.vtt) 
* TTML   (.ttml)
* SCC    (.scc)
* DFXP   (.dfxp)

## Prerequisite 
Need access to following AWS services.

* Comprehend
* Translate

Language pairs supported and limitations
https://docs.aws.amazon.com/translate/latest/dg/what-is.html#language-pairs 

## High level schematic view
![alt text](https://github.com/cloudaffair/subtitle/blob/master/misc/subtitle1.png)

## Possible Business case flow
![alt text](https://github.com/cloudaffair/subtitle/blob/master/misc/subtitle2.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'subtitle'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install subtitle

## Usage

## Subtitle initialisation
```ruby
require 'subtitle'

### Two Ways of Initialisation

Option - 1
You can use below method of initialisation in case you intend to use only transformation functionality.

subtitle = Subtitle.new(caption_file_path)

Option - 2
In case you need to use Subtitle Gem for detecting / translating subtitle, then use below way of initialisation

subtitle = Subtitle.new(caption_file_path, options)

end
where options is a hash with following keys at the minimal
<access_key_id>             : AWS Key
<secret_access_key>         : AWS Secret
<profile>[Optional]         : AWS Profile (If this is provided key and secret is not required)
<force_detect>[Optional]    : By default false. If this is true then, even if the caption file declares the language
                              we will try to infer the language. If it's false, the declared language would be returned. Is applicable only when subtile format encapsulates the language information.
<dest_lang>                 : ISO 639-2 2 Letter language code to which a caption needs to be tranlated to 
<src_lang>                  : Applicable in case if the input caption can hold cues for multiple languages, in which case the content with the matching language is picked. If not provided language will be auto detected
<outfile>                   : The destination directory in case of transform and is optional file path for language translation
<types>                     : Comma seperated strings that indicates the types to which the input caption file needs to be transformed into. For example, dfxp,ttml,srt
```

## Detect Language
```ruby
require 'subtitle'

subtitle = Subtitle.new(caption_file_path, options)
subtitle.detect_language

# By default, for TTML and DFXP files if the div contains the lang then the same would be returned
# However, you can override this behavior using force_detect option
```

## Translate Closed caption file to desired langauge
```ruby
require 'subtitle'

subtitle = Subtitle.new(caption_file_path, options)

Refer to Detect Language section above for what can be passed in options

Option 1

subtitle.translate(<dest_lang>, <src_lang>, <outfile>)

Option 2

subtitle.translate(<dest_lang>, <src_lang>)

# Creates file following the convention `caption_file_path`_`dest_lang`

Option 3

subtitle.translate(<dest_lang>)

# Detects the source langauge and creates the out file using convention `caption_file_path`_`dest_lang`

<dest_lang>   : Provide translate Language code (ISO639 2 Letter Code)
<src_lang>    : Provide  source Language code (ISO639 2 Letter Code). If not supplied, the source language will be auto detected.
<outfile>     : Destination for translated closed caption file.
```

## Identify the type if extension of the file does not exist
```ruby
require 'subtitle'

subtitle = Subtitle.new(caption_file_path)
 
# in case the <cc_file> is supplied with subtitle type SRT and the file name does not hold extension.

subtitle.type
 
Returned values
* srt
* dfxp
* vtt
* scc
 
# Returns `nil` in case does not match any type.
```

## Convert from one format to another
```ruby
require 'subtitle'

subtitle = Subtitle.new(caption_file_path)

subtitle.transform(types_to_convert, src_lang, target_lang, options)

<types_to_convert>  : An array that can hold any of the following values (dfxp, ttml, srt, vtt, scc)
<src_lang>          : can be nil or can specify the lang code in case of ttml / dfxp to extract only that section of the caption for transformation
<dest_lang>         : on the fly translation to this language
<options>           : Destination directory where the output files shall be placed

```

## Development 

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Limitation
* Translation from one language to another language is NOT supported for SCC format.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cloudaffair/subtitle. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Subtitle project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cloudaffair/subtitle/blob/master/CODE_OF_CONDUCT.md).
