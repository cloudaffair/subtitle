lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "subtitle"
  spec.version       = File.read(File.expand_path('../VERSION',__FILE__)).strip
  spec.authors       = ["Maheshwaran G"]
  spec.email         = ["pgmaheshwaran@gmail.com"]

  spec.summary       = "subtitle helps you to detect language and translate closed caption to required language"
  spec.description   = "subtitle gem to detect and translate closed caption for SubRip and WebVTT"
  spec.homepage      = "https://github.com/cloudaffair/subtitle"
  spec.license       = "MIT"

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cloudaffair/subtitle"
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  spec.require_paths = ['lib']
  spec.files = Dir['lib/*.rb','lib/engines/*.rb']

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_runtime_dependency "aws-sdk-comprehend"
  spec.add_runtime_dependency "aws-sdk-translate"
end
