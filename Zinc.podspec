Pod::Spec.new do |s|
  s.name                    = "Zinc"
  s.version                 = "0.3.0"
  s.summary                 = "Objective-C client for Zinc file distribution system."
  s.homepage                = "http://mindsnacks.github.io/Zinc/"
  s.license                 = { :type => 'BSD', :file => 'LICENSE' }
  s.author                  = { "Andy Mroczkowski" => "andy@mrox.net" }
  s.source                  = { :git => "https://github.com/mindsnacks/Zinc-ObjC.git", :tag => "#{s.version}" }

  s.ios.deployment_target   = '6.0'
  s.osx.deployment_target   = '10.8'

  s.prefix_header_file      = 'Zinc/Private/Zinc-Prefix.pch'

  s.ios.public_header_files = 'Zinc/Public/*.h', 'Zinc/Public/ios/*.h'
  s.osx.public_header_files = 'Zinc/Public/*.h', 'Zinc/Public/osx/*.h'
  
  s.ios.source_files        = 'Zinc/{Public,Private}/*.{h,m}', 'Zinc/{Public,Private}/ios/*.{h,m}'
  s.osx.source_files        = 'Zinc/{Public,Private}/*.{h,m}', 'Zinc/{Public,Private}/osx/*.{h,m}'

  s.ios.frameworks          = 'Security', 'CFNetwork', 'MobileCoreServices', 'SystemConfiguration', 'UIKit'
  s.osx.frameworks          = 'Security', 'CFNetwork'

  s.libraries               = 'z'
  s.requires_arc            = true
  s.preserve_paths          = 'Zinc/Scripts/*'

  s.dependency 'KSReachability', '~> 1.3'
  s.dependency 'AMError', '~> 0.2.6'
  s.dependency 'MSWeakTimer', '~> 1.1.0'

  s.subspec 'AdminUI' do |admin| 
    admin.ios.public_header_files = 'Zinc/Public/AdminUI/ios/*.h'
    admin.ios.source_files        = 'Zinc/{Public,Private}/AdminUI/ios/*.{h,m}'
  end

end
