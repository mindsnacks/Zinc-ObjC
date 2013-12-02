platform :ios, "6.0"
inhibit_all_warnings!

target :Zinc do
	pod 'AMError', :git => 'https://github.com/amrox/AMError.git'
	podspec :path => "Zinc.podspec"

	link_with ['Zinc', 'Zinc-OSX']

	target :Tests do
		pod 'OCMock', '~> 2.2.1'
		pod 'Kiwi', '~> 2.2.3'
		link_with 'ZincTests'
	end

	target :FunctionalTests do
		pod 'GHUnitIOS', '~> 0.5.6'
		link_with 'ZincFunctionalTests'
	end
end

