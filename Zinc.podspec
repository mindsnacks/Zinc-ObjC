Pod::Spec.new do |s|
  s.name                = "Zinc"
  s.version             = "0.0.1"
  s.summary             = "Objective-C client for Zinc file distribution system."
  s.homepage            = "http://mindsnacks.github.io/Zinc/"
  s.license             = { :type => 'BSD', :file => 'LICENSE' }
  s.author              = { "Andy Mroczkowski" => "andy@mrox.net" }
  s.source              = { :git => "https://github.com/mindsnacks/Zinc-ObjC.git", :commit => "2c845cd0e8d6a15c1a839cf153691e7b96f06bd8" }
  s.platform            = :ios, '6.0'
  s.source_files        = '{Zinc,Dependencies}/**/*.{h,m}'
  s.prefix_header_file  = 'Zinc/Private/Zinc-Prefix.pch'
  s.public_header_files = 'Zinc/Public/*.h'
  s.frameworks          = 'Security', 'MobileCoreServices', 'SystemConfiguration', 'CFNetwork'
  s.libraries           = 'z'
  s.requires_arc        = true
  s.dependency 'KSReachability', '~> 1.3'
end
