platform :ios, "6.0"
inhibit_all_warnings!

target :Zinc do

	# pod 'AMError', :git => 'https://github.com/amrox/AMError.git'
	podspec :path => "Zinc.podspec"

	target :ZincTests do
		pod 'OCMock', '~> 2.2.1'
		pod 'Kiwi', '~> 2.4.0'
	end

	target :ZincFunctionalTests do
		pod 'GHUnitIOS', '~> 0.5.6'
	end
end


