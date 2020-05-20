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
    @transcribe_service = Aws::TranscribeService::Client.new(region: @region)
    @s3 = Aws::S3::Resource.new
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

  def transcribe_uri(video_uri, lang_code, bucket_name)
    # output name of the transcribe file will be based on the Job name
    # So better create our own job name
    # They have to give the bucket name. Since we dont have access to their buckets
    # Both input and output files


    current_time = Time.now.strftime("%Y-%m-%d-%H:%M:%S")
    job_name = "transcribe-#{current_time}"

    #So output filename will be job_name.json
    resp = @transcribe_service.start_transcription_job({
        transcription_job_name: job_name,
        language_code: lang_code,
        media: {
            media_file_uri: video_uri
        },
        output_bucket_name: bucket_name
    })

    # We need to poll to check whether the transcribe is completed
    # It takes 2x to 3x time for the transcribe to complete
    complete = false
    while complete == false do 
        status = resp.transcription_job.transcription_job_status
        if (status.eql?("COMPLETED") || status.eql?("FAILED"))
            complete == true
        else
          # This can be changed based on the asset duration
          sleep(5)
        end
    end

    
    output_json_obj = @s3.bucket(bucket_name).object("#{job_name}.json")
    temp_json_output = "temp-#{job_name}.json"

    File.open(temp_json_output, 'wb') do |file|
      output_json_obj.read do |chunk|
        file.write(chunk)
      end
    end

    # The JSON output generated from Transcribe is copied to the temp folder
    # Pass this file to srthelper
    temp_json_output

  end

  def transcribe_file(file, lang_code, bucket_name)

    current_time = Time.now.strftime("%Y-%m-%d-%H:%M:%S")
    input_file_name = "tempfile-#{current_time}"
    obj = @s3.bucket(bucket_name).object(input_file_name)
    obj.upload_file(file, acl:'public-read')
    # Need to check whether we need to do polling to check file transfer is completed.

    temp_json_output = transcribe_uri(obj.public_url, lang_code, bucket_name)
    temp_json_output
  end
end

