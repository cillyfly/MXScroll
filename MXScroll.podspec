#
# Be sure to run `pod lib lint MXScroll.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MXScroll'
  s.version          = '0.1.2'
  s.summary          = 'Mix Scroll easy
'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
MXScroll is a view foundation for some mix scrollview with segmentview. it will make the work easy
                       DESC

  s.homepage         = 'https://github.com/cillyfly/MXScroll'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cillyfly' => 'cillyfly@163.com' }
  s.source           = { :git => 'https://github.com/cillyfly/MXScroll.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'
  s.source_files = 'MXScroll/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MXScroll' => ['MXScroll/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'EasyPeasy'
end
