platform :ios, "6.0"
inhibit_all_warnings!

podspec :path => "Zinc.podspec"

target :ZincTests, :exclusive => true do
	pod 'OCMock', '~> 2.2.1'
	pod 'Kiwi', '~> 2.2.1'
end

target :ZincFunctionalTests, :exclusive => true do
	pod 'GHUnitIOS', '~> 0.5.6'
end
