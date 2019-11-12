lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "subtitle"
  spec.version       = File.read(File.expand_path('../VERSION',__FILE__)).strip
  spec.authors       = ["Maheshwaran G", "Arunjeyaprasad A J"]
  spec.email         = ["pgmaheshwaran@gmail.com", "arunjeyaprasad@gmail.com"]

  spec.summary       = "Subtitle gem helps you to detect language and translate closed caption to required language"
  spec.description   = "Subtitle gem helps you to detect language and translate closed caption to required language."
  spec.homepage      = "https://github.com/cloudaffair/subtitle"
  spec.license       = "MIT"

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cloudaffair/subtitle"
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  spec.require_paths = ['lib']
  spec.files = Dir['lib/*.rb','lib/engines/*.rb']

  spec.add_development_dependency "bundler", "~> 2.0"
  #spec.add_runtime_dependency "aws-sdk-comprehend", "=1.25.0"
  #spec.add_runtime_dependency "aws-sdk-translate", "=1.17.0"
  spec.add_runtime_dependency "nokogiri", "=1.10.4"
  spec.add_development_dependency "aws-sdk", "~> 2.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "optimist"
end
