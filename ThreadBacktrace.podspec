#
# Be sure to run `pod lib lint ThreadBacktrace.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ThreadBacktrace'
  s.version          = '0.1.3'
  s.summary          = '获取线程调用栈'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Boy-Rong/ThreadBacktrace'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rongheng' => 'rongheng.rh@gmail.com' }
  s.source           = { :git => 'https://github.com/Boy-Rong/ThreadBacktrace.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'ThreadBacktrace/Classes/*.{h,m,swift}'
  s
end
