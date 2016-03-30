# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simple_rotate"

Gem::Specification.new do |spec|
    spec.name                 = SimpleRotate::LIBS_NAME
    spec.version              = SimpleRotate::VERSION
    spec.summary              = SimpleRotate::SUMMARY
    spec.description          = SimpleRotate::DESCRIPTION
    spec.homepage             = SimpleRotate::HOMEPAGE
    spec.name                 = "simple_rotate"
    spec.authors              = ["khotta"]
    spec.license              = "MIT"
    spec.email                = ["khotta116@gmail.com"]
    spec.post_install_message = "#{$-0}Thank you for installing! =(^x^="

    # include files to this gem package.
    #spec.files  = Dir["*.txt"]
    #spec.files += Dir["*.md"]
    spec.files  = Dir["lib/*.rb"]
    spec.files += Dir["lib/simple_rotate/*.rb"]
    spec.files += Dir["lib/simple_rotate/internal/*.rb"]

    # The platform this gem runs on.
    #spec.platform = Gem::Platform.local

    # required ruby version
    spec.required_ruby_version = '>= 1.9.3'

    # required path from simple_rotate
    spec.require_paths = ["lib"]
end
