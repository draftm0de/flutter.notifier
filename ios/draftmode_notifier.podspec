Pod::Spec.new do |s|
  s.name             = 'draftmode_notifier'
  s.version          = '0.0.0'
  s.summary          = 'DraftMode actionable notification helper.'
  s.description      = <<-DESC
DraftMode Notifier wires FlutterLocalNotifications so notification taps on iOS
route back into Flutter without requiring manual AppDelegate changes.
DESC
  s.homepage         = 'https://draftmode.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'DraftMode' => 'dev@draftmode.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.platform         = :ios, '13.0'
  s.dependency 'Flutter'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
