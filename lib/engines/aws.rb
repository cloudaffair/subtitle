require 'aws-sdk'
require 'aws-sdk'
require_relative 'translator'

# 
# Provides Language services using Amazon Translate
#
# Module can be intialized using multiple options
#
# == Credential Referencing Order
#
# * [Arguments]             - Pass the credentials access_key_id and secret_access_key as arguments
# * [Environment route]     - AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY can be exposed as environment variables
# * [Profile Name]          - The application uses the credentials of the system and picks the credentials 
#                             referred to by the profile
#
class AwsEngine
  include Translator

  DEFAULT_REGION = ENV["AWS_DEFAULT_REGION"] || "us-east-1"

  # 
  # :args: options
  #
  # ==== Arguments
  # options can carry the following details
  #
  # * [:access_key_id]      - access key id
  # * [:secret_access_key]  - Secret access key
  # * [:env]                - true for using credentials from environment variables
  # * [:profile]            - profile name for using shared credentials setup
  # * [:region]             - If not provided defaults to us-east-1
  #
  # ==== raises                 
  #
  # * EngineInitializationException if credentials cannot be setup due to lack of details
  # * Aws Exceptions if profile name is invalid or invalid credentials are passed
  # 
  def initialize(options)
    access_key_id = nil
    secret_access_key = nil
    @region = options[:region] || DEFAULT_REGION
    if options[:env]
      access_key_id = ENV["AWS_ACCESS_KEY_ID"]
      secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
    elsif options[:access_key_id] && options[:secret_access_key]
      access_key_id = options[:access_key_id]
      secret_access_key = options[:secret_access_key]
    end
    if access_key_id && secret_access_key
      Aws.config.update({
        region: options[:region] || DEFAULT_REGION,
        credentials: Aws::Credentials.new(access_key_id, secret_access_key)
      })
    elsif options[:profile]
      credentials = Aws::SharedCredentials.new(profile_name: options[:profile])
      Aws.config.update({
        region: @region,
        credentials: credentials.credentials
      })
    else
      raise Translator::EngineInitializationException.new(
        "Failed to initialize Aws Engine. Credentials are missing / not provided")
    end
    @translate_service  = Aws::Translate::Client.new(region: @region)
    @comprehend_service = Aws::Comprehend::Client.new(region: @region)
  end

  # 
  # Invokes the language detection API of AWS and returns only the language
  # of the highest score and returns the ISO 639-1 code
  #
  # * +text+ - The text for which the language is to be inferred
  # 
  def infer_language(text)
    response = @comprehend_service.detect_dominant_language({ text: "#{text}" })
    response[:languages][0][:language_code]
  end

  # 
  # Invokes the translation API of AWS and returns the translated text
  # as per the arguments provided.
  # Will Raise exception if a translation cannot be made between the source
  # and target language codes or if the lang code is invalid
  #
  # * +input_text+      - The text that needs to be translated
  # * +src_lang+        - The source language of the text
  # * +target_lang+     - The target language to which the input_text needs to be translated to
  #
  def translate(input_text, src_lang, target_lang)
    response = @translate_service.translate_text({ :text => "#{input_text}" , 
      :source_language_code => "#{src_lang}", :target_language_code => "#{target_lang}"})
    response.translated_text
  end
end

