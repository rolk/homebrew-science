# This file is licensed under the GNU General Public License v3.0
require 'formula'

class Tinyxml < Formula
  homepage 'http://grinninglizard.com/tinyxml/'
  url      'http://downloads.sf.net/project/tinyxml/tinyxml/2.6.2/tinyxml_2_6_2.zip'
  sha1     'a425a22ff331dafa570b2a508a37a85a4eaa4127'

  def patches
    # make it so it always compile with STL (like on Debian)
    DATA
  end

  def install
    # parse version number
    major = version.to_s.split('.')[0]
    minor = version.to_s.split('.')[1]
    name = 'tinyxml'

    # remove GNU toolchain specific compiler settings
    inreplace 'Makefile' do |s|
      #s.remove_make_var! 'CXX'
      #s.remove_make_var! 'LD'
      s.gsub! /^CXX\ *:=.*$/, 'CXX:=$(CXX) -fno-common'
      s.gsub! /^LD\ *:=.*$/, 'LD:=$(CXX)'
      s.gsub! /^TINYXML_USE_STL\ *:=.*$/, 'TINYXML_USE_STL:=YES'
    end

    # compile all source units by making the example program
    system 'make'

    # these are the object files that are produced by the above
    objs = Dir.glob 'tiny*.o'

    # create the static library    
    system 'ar', 'r', "lib#{name}.a", *objs
    system 'ranlib', "lib#{name}.a"

    # create the dynamic library
    args = %W[ -dynamiclib
               -all_load
               -headerpad_max_install_names
               -install_name \"#{lib}/lib#{name}.#{version}.dylib\"
               -compatibility_version #{major}
               -current_version #{version}
               -o lib#{name}.#{version}.dylib ] + objs
    system ENV.cxx, *args

    # pkg-config file; this is small enough to put inline here
    File::open("#{name}.pc", 'w') do |f|
      f << <<-EOF.undent
        prefix=#{HOMEBREW_PREFIX}
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: TinyXml
        Description: Simple, small, C++ XML parser
        Version: #{version}
        Libs: -L${libdir} -l#{name}
        Cflags: -I${includedir}
      EOF
    end

    # make sure we have somewhere to put the files
    lib.mkpath
    (lib+"pkgconfig").mkpath
    include.mkpath
    doc.mkpath
    
    # copy these to their final location
    include.install "#{name}.h"
    #include.install "tinystr.h"
    lib.install "lib#{name}.a"
    lib.install "lib#{name}.#{version}.dylib"
    (lib+"pkgconfig").install "#{name}.pc"
    doc.install (Dir.glob 'docs/*')

    # set up version compatibility for the dynamic library
    cd lib do
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.#{minor}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.#{major}.dylib"
      ln_s "lib#{name}.#{version}.dylib", "lib#{name}.dylib"
    end
  end
end

__END__
--- a/tinyxml.h
+++ b/tinyxml.h
@@ -26,6 +26,10 @@
 #ifndef TINYXML_INCLUDED
 #define TINYXML_INCLUDED
 
+#ifndef TIXML_USE_STL
+#define TIXML_USE_STL
+#endif
+
 #ifdef _MSC_VER
 #pragma warning( push )
 #pragma warning( disable : 4530 )
