Pod::Spec.new do |s|
  s.name                = "Zinc"
  s.version             = "0.0.1"
  s.summary             = "Objective-C client for Zinc file distribution system."
  s.homepage            = "http://mindsnacks.github.io/Zinc/"
  s.license             = { :type => 'BSD', :file => 'LICENSE' }
  s.author              = { "Andy Mroczkowski" => "andy@mrox.net" }
  s.source              = { :git => "https://github.com/mindsnacks/Zinc-ObjC.git", :commit => "fc9de46183a3b272c2bde5d00f0699c6d5bfcbdf" }
  s.platform            = :ios, '6.0'
  s.source_files        = 'Zinc/**/*.{h,m}'
  s.prefix_header_file  = 'Zinc/Private/Zinc-Prefix.pch'
  s.public_header_files = 'Zinc/Public/*.h'
  s.frameworks          = 'Security', 'MobileCoreServices', 'SystemConfiguration', 'CFNetwork'
  s.libraries           = 'z'
  s.requires_arc        = true
  s.preserve_paths      = 'Zinc/Scripts/*'
  s.dependency 'KSReachability', '~> 1.3'
  s.dependency 'AMFoundation', '~> 0.1.4'
end
