Pod::Spec.new do |s|
  s.name             = 'fast_image_editor'
  s.version          = '0.1.0'
  s.summary          = 'Native image editing for Flutter with region-based effects'
  s.description      = 'High-performance native C image filters (blur, sepia, saturation, brightness, contrast, sharpen, grayscale) with region support'
  s.homepage         = 'https://github.com/erykkruk/fast_image_editor'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Eryk Kruk' => 'eryk@codigee.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift', 'src/**/*.{h,cpp}'
  s.public_header_files = 'src/**/*.h'
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_CFLAGS' => '-fvisibility=default',
    'STRIP_STYLE' => 'non-global',
    'DEAD_CODE_STRIPPING' => 'NO',
    'STRIP_INSTALLED_PRODUCT' => 'NO'
  }

  s.user_target_xcconfig = {
    'STRIP_STYLE' => 'non-global',
    'DEAD_CODE_STRIPPING' => 'NO'
  }

  s.dependency 'Flutter'
end
