Pod::Spec.new do |s|
  s.name             = 'MKKRightToLeftScrollView'
  s.version          = '0.1.0'
  url                = "https://github.com/aiaf/MKKRightToLeftScrollView"
  git_url            = "#{url}.git"
  s.summary          = 'A right-to-left NSScrollView that displays vertical scrollers on the left instead of right.'
  s.description      = <<-DESC
MKKRightToLeftScrollView laterally inverts scrollers on macOS. This means that the vertical scrollers appear on the left side instead of the right.

This is useful for content that is oriented from right-to-left, such as an `NSTextView` with Arabic text.

On macOS 10.12, horizontally inverted scrollers were natively implemented, but require that `[NSApp userInterfaceLayoutDirection]` be set to `NSUserInterfaceLayoutDirectionRightToLeft`, which is not programmatically controllable. 

In other words, the app's `userInterfaceLayoutDirection` affects all `NSScrollView`s in the app, hardly desirable for most use cases.

Additionally, the native implementation does not correctly mirror vertical scrollers.

The code subclasses `NSScrollView` and `NSScroller`.
There's also optional, but recommended, private method swizzling on `NSOverlayScrollerImp`.

`contentInsets` introduced in macOS 10.10 are also supported.

This code was originally created for https://katibapp.com/
                       DESC

  s.homepage         = 'https://github.com/aiaf/MKKRightToLeftScrollView'
  s.screenshots     = 'https://i.imgur.com/silOzZU.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Abdullah Arif' => 'abdullah.a@gmail.com' }
  s.source           = { :git => 'https://github.com/aiaf/MKKRightToLeftScrollView.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/abdullaharif'


  s.source_files = 'MKKRightToLeftScrollView/**/*'
  s.osx.deployment_target = "10.8"
end
