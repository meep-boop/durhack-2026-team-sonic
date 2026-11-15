Pod::Spec.new do |s|
  s.name           = 'SonicAr'
  s.version        = '1.0.0'
  s.summary        = 'ARKit + RealityKit view for the Team Sonic app'
  s.description    = 'Plane placement, image tracking and measuring, wrapped as an Expo native view.'
  s.author         = ''
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '16.4'
  }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.frameworks = 'ARKit', 'RealityKit'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
