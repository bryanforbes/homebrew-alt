require 'formula'

class Princexml < Formula
  url 'http://www.princexml.com/download/prince-8.0-macosx.tar.gz'
  homepage 'http://www.princexml.com'
  md5 '0d17a2e9c82277ed5d039444ebf9cecd'
  version '8.0'

  def patches
    # Drop the user input since we're providing the prefix
    DATA
  end

  def install
    system "export prefix=#{prefix};./install.sh"
  end
end


__END__
--- prince-8.0-macosx.orig/install.sh	2011-06-30 19:16:13.000000000 -0600
+++ prince-8.0-macosx/install.sh	2012-02-13 13:36:07.000000000 -0700
@@ -5,24 +5,10 @@
 VERSION="8.0"
 WEBSITE="http://www.princexml.com"
 
-prefix=/usr/local
-
 base=`dirname $0`
 
 cd "$base"
 
-echo "$PRODUCT $VERSION"
-echo
-echo "Install directory"
-echo "    This is the directory in which $PRODUCT $VERSION will be installed."
-echo "    Press Enter to accept the default directory or enter an alternative."
-echo -n "    [$prefix]: "
-
-read input
-if [ ! -z "$input" ] ; then
-    prefix="$input"
-fi
-
 echo
 echo "Installing $PRODUCT $VERSION..."
