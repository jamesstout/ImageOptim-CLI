require 'formula'

class ImageoptimCli < Formula
  homepage 'http://jamiemason.github.io/ImageOptim-CLI/'
  url 'https://github.com/JamieMason/ImageOptim-CLI/archive/1.6.13.tar.gz'
  sha1 'd9d3151d96400f408f616f64f83012cffcdb65a4'
  head 'https://github.com/JamieMason/ImageOptim-CLI.git'

  depends_on 'pngquant' => :optional
  # no idea how to say depends on imageOptim.app
  # maybe we need a Makefile/install script
  # in fact we do - if we want to use the Ruby gems
  # we need to know how they are using Ruby: System, rbenv, rvm, 

  def install
    bin.install "bin/imageOptimAppleScriptLib", "bin/imageOptim"
  end

  def caveats
    "ImageOptim-CLI requires ImageOptim.app in /Applications and optionally ImageAlpha and JPEGmini"
  end

  test do
    system "#{bin}/imageOptim", "--version"
  end
end
