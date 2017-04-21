
Pod::Spec.new do |s|

  s.name         = "Swiftly"
  s.version      = "1.0"
  s.summary      = "Extension of Objective-C library."
  s.description  = <<-DESC
	This is a extension of Objective-C, which can develop swiftly.
                   DESC

  s.homepage     = "https://github.com/briceZhao/Swiftly"
  s.license      = "MIT"
  s.author             = { "briceZhao" => "zx_brice@126.com" }
  s.platform     = :ios, "9.0"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/briceZhao/Swiftly.git", :tag => "#{s.version}" }
  s.source_files  = "Swiftly/*"
  s.requires_arc = true 
  s.framework  = "UIKit"

  # s.public_header_files = "Classes/**/*.h"

end
