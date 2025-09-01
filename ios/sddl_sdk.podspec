Pod::Spec.new do |s|
  s.name             = 'sddl_sdk'
  s.version          = '0.1.4'
  s.summary          = 'SDDL Flutter SDK'
  s.description      = <<-DESC
A Flutter plugin that exposes Android Install Referrer and adds client headers.
  DESC
  s.homepage         = 'https://sddl.me'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SimpleLink' => 'dev@sddl.me' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '11.0'
  s.static_framework = true
  s.dependency 'Flutter'

  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end