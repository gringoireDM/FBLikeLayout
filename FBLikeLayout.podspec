
Pod::Spec.new do |s|

  s.name         = "FBLikeLayout"
  s.version      = "1.2"
  s.summary      = "A UICollectionView Layout inspired by Facebook photos section."

  s.description  = <<-DESC
				This is an UICollectionView layout inspired by the photo section of facebook.
				This layout loads squared items with randomic full size items.
				It works with standard layout delegate methods. No additional custom methods to be implemented.
                   DESC

  s.license      = { :type => 'MIT' }
  s.homepage = "https://github.com/gringoireDM/FBLikeLayout.git"

  s.author             = { "Giuseppe Lanza" => "gringoire986@gmail.com" }
  s.social_media_url   = "http://twitter.com/gringoireDM"
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/gringoireDM/FBLikeLayout.git", :tag => "1.2" }

  s.source_files  = "FBLikeLayout Sample/FBLikeLayout", "FBLikeLayout Sample/FBLikeLayout/*.{h,m}", "FBLikeLayout Sample/FBLikeLayout/**/*.{h,m}"

end
