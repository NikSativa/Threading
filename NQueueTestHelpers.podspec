Pod::Spec.new do |spec|
    spec.name         = "NQueueTestHelpers"
    spec.version      = "1.1.14"
    spec.summary      = "Queue wrapper of DispatchQueue"

    spec.source       = { :git => "git@github.com:NikSativa/NQueue.git" }
    spec.homepage     = "https://github.com/NikSativa/NQueue"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = '11.0'
    spec.swift_version = '5.5'

    spec.frameworks = 'XCTest', 'Foundation', 'UIKit'

    spec.scheme = {
      :code_coverage => true
    }

    spec.source_files = 'TestHelpers/**/*.{storyboard,xib,swift}'

    spec.dependency 'NQueue'
    spec.dependency 'NSpry'

    spec.test_spec 'Tests' do |tests|
        #        tests.requires_app_host = true
        tests.dependency 'Quick'
        tests.dependency 'Nimble'
        tests.dependency 'NSpry_Nimble'
        tests.dependency 'NQueue'

        tests.source_files = 'Tests/**/*.*'
    end
end
