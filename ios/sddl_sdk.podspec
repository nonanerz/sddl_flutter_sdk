Pod::Spec.new do |s|
  s.name             = 'sddl_sdk'
  s.version          = '0.1.3'
  s.summary          = 'SDDL Flutter SDK plugin (install referrer on Android, no-op on iOS).'
  s.description      = <<-DESC
A Flutter plugin for SDDL deep links and attribution.
Android: install referrer via Play API; iOS: no-op stub.
  DESC
  s.homepage         = 'https://sddl.me'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SimpleLink' => 'support@sddl.me' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '13.0'
  s.source_files        = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency          'Flutter'
  s.static_framework    = true
end