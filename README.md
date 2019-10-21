# Subtitle

Welcome to `subtitle` gem!. Following functionalities are provided using AWS services.

* Detect the Language code for the given Subtitle file
* Translates the given subtitle file to required suggested language.

Supports following subtitle files

* SubRip (.srt)
* WebVTT (.vtt) 

## Prerequisite 
Need access to following AWS services.

* Comprehend
* Translate

Language pairs supported and limitations
https://docs.aws.amazon.com/translate/latest/dg/what-is.html#language-pairs 

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

## Detect Language
```ruby
require 'subtitle'

subtitle = Subtitle.new(<aws_key>, <aws_secret>, <cc_file>)
subtitle.detect_language

<aws_key>     : AWS Key
<aws_secret>  : AWS Secret
<cc_file>     : Closed Caption File
```

## Translate Closed caption file to desired langauge
```ruby
require 'subtitle'

subtitle = Subtitle.new(<aws_key>, <aws_secret>, <cc_file>)

<aws_key>     : AWS Key
<aws_secret>  : AWS Secret
<cc_file>     : Closed Caption File

Option 1

subtitle.translate_cc(<dest_lang>, <src_lang> ,<outfile>)

Option 2

subtitle.translate_cc(<dest_lang>, <src_lang>)

Option 3

subtitle.translate_cc(<dest_lang>)

<dest_lang>   : Provide translate Language code (ISO639 2 Letter Code)
<src_lang>    : Provide  source Language code (ISO639 2 Letter Code). If not supplied, the source language will be auto detected.
<outfile>     : Destination for translated closed caption file.
```


## Development 

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pgmaheshwaran/subtitle. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Subtitle project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/subtitle/blob/master/CODE_OF_CONDUCT.md).
