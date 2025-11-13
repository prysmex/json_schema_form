# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsf/version'

Gem::Specification.new do |spec|
  spec.name          = 'json_schema_form'
  spec.version       = JSF::VERSION
  spec.authors       = ['Pato']
  spec.email         = ['pato_devilla@hotmail.com']

  spec.summary       = 'Convinient way to manage json schema forms'
  spec.description   = 'Convinient way to manage json schema forms'
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4.7'

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 7.2'
  spec.add_dependency 'super_hash', '~> 0.3'
  spec.add_dependency 'dry-schema', '1.14.1'
  spec.add_dependency 'json_schemer', '2.4.0'
end
