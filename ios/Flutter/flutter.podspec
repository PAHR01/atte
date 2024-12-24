Pod::Spec.new do |s|
  s.name         = 'Flutter'
  s.version      = '1.0.0'
  s.summary      = 'Flutter is a mobile app SDK'
  s.ios.deployment_target = '9.0'
  s.requires_arc = true
  s.source       = { :git => 'https://github.com/flutter/flutter.git', :branch => 'stable' }
  s.ios.source_files = 'Flutter.framework/Headers/*.h'
  s.resource_bundles = {
    'Flutter' => ['Flutter.framework/**/*']
  }
end
