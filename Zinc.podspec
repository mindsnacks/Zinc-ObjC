Pod::Spec.new do |s|
  s.name         = "Zinc"
  s.version      = "0.0.1"
  s.summary      = "Objective-C client for Zinc file distribution system."
  s.homepage     = "http://mindsnacks.github.io/Zinc/"
  s.license      = { :type => 'BSD', :file => 'LICENSE' }
  s.author       = { "Andy Mroczkowski" => "andy@mrox.net" }
  s.source       = { :git => "https://github.com/mindsnacks/Zinc-ObjC.git", :commit => "1bdd4d38eb3ce783e53a938a3eb548cb2bfab88b" }
  s.platform     = :ios, '6.0'
  s.source_files = '{Zinc,Dependencies}/**/*.{h,m}'
  s.prefix_header_file = 'Zinc/Zinc-Prefix.pch'
  s.public_header_files = 'Zinc/Zinc.h', 'Zinc/ZincGlobals.h', 'Zinc/ZincErrors.h', 'Zinc/ZincRepo.h', 'Zinc/ZincAgent.h', 'Zinc/ZincBundle.h', 'Zinc/ZincResource.h', 'Zinc/ZincBundleTrackingRequest.h', 'Zinc/ZincEvent.h', 'Zinc/ZincTaskRef.h', 'Zinc/ZincDownloadPolicy.h', 'Zinc/ZincProgress.h', 'Zinc/ZincActivityMonitor.h', 'Zinc/ZincTaskMonitor.h', 'Zinc/ZincRepoMonitor.h', 'Zinc/ZincBundleAvailabilityMonitor.h', 'Zinc/UIImage+Zinc.h', 'Zinc/ZincUtils.h', 'Zinc/ZincOperations.h'
  s.frameworks = 'Security', 'MobileCoreServices', 'SystemConfiguration', 'CFNetwork'
  s.libraries = 'z'
  s.requires_arc = true
  s.dependency 'KSReachability', '~> 1.3'
end
