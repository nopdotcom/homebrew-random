class ArgyllCms < Formula
  desc "ICC compatible color management system"
  homepage "https://www.argyllcms.com/"
  url "https://www.argyllcms.com/Argyll_V2.1.2_src.zip"
  version "2.1.2"
  sha256 "be378ca836b17b8684db05e9feaab138d711835ef00a04a76ac0ceacd386a3e3"
  license "AGPL-3.0"

  livecheck do
    url "https://www.argyllcms.com/downloadsrc.html"
    regex(/href=.*?Argyll[._-]v?(\d+(?:\.\d+)+)[._-]src\.zip/i)
  end

  bottle do
    sha256 cellar: :any, catalina:    "242a8a56d37402e681d630d1df0702088df5555e367afb65469679aa96ee9f29"
    sha256 cellar: :any, mojave:      "6edcbef10d3f93d7f527cc875a35cb9c6bf636da03d6a1c548f560fcbca83866"
    sha256 cellar: :any, high_sierra: "4b7bcbe2cd555d9606812afc676cab750c6f8bc4be54db0551bb2becefd176e0"
  end

  depends_on "jam" => :build
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "xz"

  conflicts_with "num-utils", because: "both install `average` binaries"

  # Fixes calls to obj_msgSend, whose signature changed in macOS 10.15.
  # Follows the advice in this blog post, which should be compatible
  # with both older and newer versions of macOS.
  # https://www.mikeash.com/pyblog/objc_msgsends-new-prototype.html
  # Submitted upstream: https://www.freelists.org/post/argyllcms/Patch-Fix-macOS-build-failures-from-obj-msgSend-definition-change
  patch do
    url "https://www.freelists.org/archives/argyllcms/02-2020/binRagOo4qV7a.bin"
    # url "https://www.freelists.org/archives/argyllcms/02-2020/bin7VecLntD2x.bin"
    sha256 "fa86f5f21ed38bec6a20a79cefb78ef7254f6185ef33cac23e50bb1de87507a4"
  end

  patch :DATA

  def install
    # dyld: lazy symbol binding failed: Symbol not found: _clock_gettime
    # Reported 20 Aug 2017 to graeme AT argyllcms DOT com
    if MacOS.version == :el_capitan && MacOS::Xcode.version >= "8.0"
      inreplace "numlib/numsup.c", "CLOCK_MONOTONIC", "UNDEFINED_GIBBERISH"
    end

    system "sh", "makeall.sh"
    system "./makeinstall.sh"
    rm "bin/License.txt"
    prefix.install "bin", "ref", "doc"
  end

  test do
    system bin/"targen", "-d", "0", "test.ti1"
    system bin/"printtarg", testpath/"test.ti1"
    %w[test.ti1.ps test.ti1.ti1 test.ti1.ti2].each do |f|
      assert_predicate testpath/f, :exist?
    end
    assert_match "Calibrate a Display", shell_output("#{bin}/dispcal 2>&1", 1)
  end
end
__END__
diff --git a/png/png.h b/png/png.h
index 75e8736..621cfdf 100755
--- a/png/png.h
+++ b/png/png.h
@@ -3226,6 +3226,7 @@ PNG_EXPORT(243, int, png_get_palette_max, (png_const_structp png_ptr,
  *           selected at run time.
  */
 #ifdef PNG_SET_OPTION_SUPPORTED
+#undef PNG_ARM_NEON_API_SUPPORTED
 #ifdef PNG_ARM_NEON_API_SUPPORTED
 #  define PNG_ARM_NEON   0 /* HARDWARE: ARM Neon SIMD instructions supported */
 #endif
diff --git a/png/pngpriv.h b/png/pngpriv.h
index c498313..adad60f 100755
--- a/png/pngpriv.h
+++ b/png/pngpriv.h
@@ -120,7 +120,7 @@
     * to compile with an appropriate #error if ALIGNED_MEMORY has been turned
     * off.
     */
-#  if defined(__ARM_NEON__) && defined(PNG_ALIGNED_MEMORY_SUPPORTED)
+#  if 0 && defined(__ARM_NEON__) && defined(PNG_ALIGNED_MEMORY_SUPPORTED)
 #     define PNG_ARM_NEON_OPT 2
 #  else
 #     define PNG_ARM_NEON_OPT 0
diff --git a/tiff/Jamfile b/tiff/Jamfile
index 561df86..ec36101 100755
--- a/tiff/Jamfile
+++ b/tiff/Jamfile
@@ -8,7 +8,7 @@ if $(UNIX) {
 	DEFINES += "unix" ;			# libtiff assumes this
 	# Genfile actually creates libtiff/tif_config.h and libtiff/tiffconf.h:
 	GenFileNND libtiff/tif_config.h :
-	          "(cd $(SUBDIR); chmod +x configure ; ./configure --disable-old-jpeg --disable-pixarlog --disable-zlib --disable-jbig)" : configure ;
+	          "(cd $(SUBDIR); chmod +x configure ; ./configure --disable-old-jpeg --disable-pixarlog --disable-zlib --disable-jbig --disable-lzma)" : configure ;
 #	          "(cd $(SUBDIR); chmod +x configure ; ./configure --disable-jpeg --disable-old-jpeg --disable-pixarlog --disable-zlib --disable-jbig)" : configure ;
 	# Workaround Jam problem of two products from one action:
 	FakeFile libtiff/tiffconf.h : libtiff/tif_config.h ;
diff --git a/zlib/gzlib.c b/zlib/gzlib.c
index fae202e..689b276 100755
--- a/zlib/gzlib.c
+++ b/zlib/gzlib.c
@@ -4,6 +4,7 @@
  */
 
 #include "gzguts.h"
+#include <unistd.h>
 
 #if defined(_WIN32) && !defined(__BORLANDC__)
 #  define LSEEK _lseeki64
diff --git a/zlib/gzread.c b/zlib/gzread.c
index bf4538e..0e6d497 100755
--- a/zlib/gzread.c
+++ b/zlib/gzread.c
@@ -3,6 +3,9 @@
  * For conditions of distribution and use, see copyright notice in zlib.h
  */
 
+#include <sys/types.h>
+#include <sys/uio.h>
+#include <unistd.h>
 #include "gzguts.h"
 
 /* Local functions */
diff --git a/zlib/gzwrite.c b/zlib/gzwrite.c
index aa767fb..d24f32a 100755
--- a/zlib/gzwrite.c
+++ b/zlib/gzwrite.c
@@ -4,6 +4,9 @@
  */
 
 #include "gzguts.h"
+#include <sys/types.h>
+#include <sys/uio.h>
+#include <unistd.h>
 
 /* Local functions */
 local int gz_init OF((gz_statep));
