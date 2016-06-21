# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'omniauth-xiaomi/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-xiaomi"
  spec.version       = Omniauth::Xiaomi::VERSION
  spec.authors       = ["Eugen Mamaev"]
  spec.email         = ["mevgeniii@mail.ru"]

  spec.summary       = %q{OmniAuth OAuth2 strategy for Xiaomi}
  spec.description   = %q{OmniAuth OAuth2 strategy for Xiaomi}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($\)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'omniauth-oauth2', '~> 1.4'
  spec.add_runtime_dependency 'multi_xml'
end
