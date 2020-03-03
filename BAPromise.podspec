Pod::Spec.new do |s|
s.name             = "BAPromise"
s.version          = "3.2.0"
s.summary          = "Objective C Promise Library"
s.description      = <<-DESC
    Swift Promise Library. An alternative to NSOperation for asynchronous operations.
DESC
s.homepage         = "https://github.com/benski/BAPromise"
s.license          = "MIT"
s.author           = { "Ben Allison" => "benski@winamp.com" }
s.source           = { :git => "https://github.com/benski/BAPromise.git", :tag => s.version.to_s }
s.swift_versions = ['4.2', '5.0', '5.1']

s.ios.deployment_target = '10.0'
s.osx.deployment_target = '10.12'
s.tvos.deployment_target = '10.0'
s.requires_arc = true

s.source_files = 'Classes/*'

s.public_header_files = 'Classes/BAPromise.h'

end
