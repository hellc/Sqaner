Pod::Spec.new do |s|

  s.swift_versions         = '5.0'
  s.name                   = 'Sqaner'
  s.version                = '0.0.1'
  s.summary                = 'Sequential documents scanner framework'
  s.homepage               = 'https://github.com/hellc/Sqaner'
  s.license                = 'MIT'
  s.author                 = { 'Ivan Manov' => 'ivanmanov@live.com' }
  s.social_media_url       = 'https://twitter.com/justhellc'

  s.requires_arc           = false
  s.ios.deployment_target  = '11.0'
  
  s.resources              = "Sources/Sqaner/**/*.{storyboard,xib,xcassets}"
  s.resource_bundles = {
   'Sqaner' => [
       'Sources/Sqaner/**/*.{storyboard,xib,xcassets}'
   ]
  }

  s.source                 = { :git => 'https://github.com/hellc/Sqaner.git', :tag => s.version }
  s.source_files           = 'Sources/Sqaner/**/*.swift'
  
end
