Pod::Spec.new do |s|
s.name             = "BAPromise"
s.version          = "1.2.2"
s.summary          = "Objective C Promise Library"
s.description      = <<-DESC
    Objective C Promise Library. An alternative to NSOperation for asynchronous operations.
DESC
s.homepage         = "https://github.com/benski/BAPromise"
s.license          = "MIT"
s.author           = { "Ben Allison" => "benski@winamp.com" }
s.source           = { :git => "https://github.com/benski/BAPromise.git", :tag => s.version.to_s }
#s.social_media_url = 'https://twitter.com/NAME'

s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.10'
s.tvos.deployment_target = '9.0'
s.requires_arc = true

s.source_files = 'Classes/*'

s.public_header_files = 'Classes/BAPromise.h'

end
