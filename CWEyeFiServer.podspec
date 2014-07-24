#
# Be sure to run `pod lib lint CWEyeFiServer.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CWEyeFiServer"
  s.version          = "0.0.1"
  s.summary          = "Provides an Eye-Fi server for objective-c applications"
  s.description      = <<-DESC
                        Provides an Eye-Fi server for objective-c applications
                       DESC
  s.homepage         = "https://github.com/codewhisper/eye-fi-server"
  s.license          = 'GPL'
  s.author           = { "Michael Litvak" => "michael@codewhisper.com" }
  s.source           = { :git => "https://github.com/codewhisper/eye-fi-server.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*.xml'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'CocoaHTTPServer', '~> 2.3'
  s.dependency 'Brett', '~> 1.0'
end
