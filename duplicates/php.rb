require 'formula'

def mysql_installed?
  `which mysql_config`.length > 0
end

class Php < Formula
  url 'http://www.php.net/get/php-5.3.8.tar.gz/from/this/mirror'
  homepage 'http://php.net/'
  md5 'f4ce40d5d156ca66a996dbb8a0e7666a'
  version '5.3.8'

  # So PHP extensions don't report missing symbols
  skip_clean ['bin', 'sbin']

  depends_on 'gettext'
  depends_on 'readline' unless ARGV.include? '--without-readline'
  depends_on 'libxml2'
  depends_on 'jpeg'
  depends_on 'mcrypt'

  if ARGV.include? '--with-mysql'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
  if ARGV.include? '--with-fpm'
    depends_on 'libevent'
  end
  if ARGV.include? '--with-pgsql'
    depends_on 'postgresql'
  end
  if ARGV.include? '--with-mssql'
    depends_on 'freetds'
  end
  if ARGV.include? '--with-intl'
    depends_on 'icu4c'
  end

  def options
   [
     ['--with-mysql', 'Include MySQL support'],
     ['--with-pgsql', 'Include PostgreSQL support'],
     ['--with-mssql', 'Include MSSQL-DB support'],
     ['--with-fpm', 'Enable building of the fpm SAPI executable (implies --without-apache)'],
     ['--without-apache', 'Build without shared Apache 2.0 Handler module'],
     ['--with-intl', 'Include internationalization support'],
     ['--without-readline', 'Build without readline support']
   ]
  end

  def patches; DATA; end

  def install
    ENV.O3 # Speed things up

    args = [
      "--disable-debug",
      "--prefix=#{prefix}",
      "--sysconfdir=#{etc}/php",
      "--with-config-file-path=#{etc}/php",
      "--with-config-file-scan-dir=#{etc}/php/conf.d",
      "--localstatedir=#{HOMEBREW_PREFIX}/var",
      "--with-iconv-dir=/usr",
      "--enable-dba",
      "--enable-ndbm=/usr",
      "--enable-exif",
      "--enable-soap",
      "--enable-sqlite-utf8",
      "--enable-wddx",
      "--enable-ftp",
      "--enable-sockets",
      "--enable-zip",
      "--enable-pcntl",
      "--enable-shmop",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--enable-sysvmsg",
      "--enable-mbstring",
      "--enable-mbregex",
      "--enable-zend-multibyte",
      "--enable-bcmath",
      "--enable-calendar",
      "--with-openssl=/usr",
      "--with-zlib=/usr",
      "--with-bz2=/usr",
      "--with-ldap",
      "--with-ldap-sasl=/usr",
      "--with-xmlrpc",
      "--with-iodbc",
      "--with-kerberos=/usr",
      "--with-libxml-dir=#{Formula.factory('libxml2').prefix}",
      "--with-xsl=/usr",
      "--with-curl=/usr",
      "--with-gd",
      "--enable-gd-native-ttf",
      "--with-freetype-dir=/usr/X11",
      "--with-mcrypt=#{Formula.factory('mcrypt').prefix}",
      "--with-jpeg-dir=#{Formula.factory('jpeg').prefix}",
      "--with-png-dir=/usr/X11",
      "--with-gettext=#{Formula.factory('gettext').prefix}",
      "--with-snmp=/usr",
      "--with-tidy",
      "--mandir=#{man}"
    ]

    # Enable PHP FPM
    if ARGV.include? '--with-fpm'
      args.push "--enable-fpm"
    end

    # Build Apache module by default
    unless ARGV.include? '--with-fpm' or ARGV.include? '--without-apache'
      args.push "--with-apxs2=/usr/sbin/apxs"
      args.push "--libexecdir=#{prefix}/libexec"
    end

    if ARGV.include? '--with-mysql'
      args.push "--with-mysql-sock=/tmp/mysql.sock"
      args.push "--with-mysqli=mysqlnd"
      args.push "--with-mysql=mysqlnd"
      args.push "--with-pdo-mysql=mysqlnd"
    end

    if ARGV.include? '--with-pgsql'
      args.push "--with-pgsql=#{Formula.factory('postgresql').prefix}"
      args.push "--with-pdo-pgsql=#{Formula.factory('postgresql').prefix}"
    end

    if ARGV.include? '--with-mssql'
      args.push "--with-mssql=#{Formula.factory('freetds').prefix}"
    end

    if ARGV.include? '--with-intl'
      args.push "--enable-intl"
      args.push "--with-icu-dir=#{Formula.factory('icu4c').prefix}"
    end

    args.push "--with-readline=#{Formula.factory('readline').prefix}" unless ARGV.include? '--without-readline'

    system "./configure", *args

    unless ARGV.include? '--without-apache'
      # Use Homebrew prefix for the Apache libexec folder
      inreplace "Makefile",
        "INSTALL_IT = $(mkinstalldirs) '$(INSTALL_ROOT)/usr/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='$(INSTALL_ROOT)/usr/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so",
        "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so"
    end

    if ARGV.include? '--with-intl'
      inreplace 'Makefile' do |s|
        s.change_make_var! "EXTRA_LIBS", "\\1 -lstdc++"
      end
    end

    system "make"
    system "make install"

    etc_php = (etc + "php")
    if not etc_php.exist?
      etc_php.mkdir
    end

    etc_php.install "./php.ini-production" => "php.ini" unless File.exists? etc_php+"php.ini"
    if ARGV.include? '--with-fpm'
        system "cp ./sapi/fpm/php-fpm.conf #{etc_php}/php-fpm.conf" unless File.exists? "#{etc_php}/php-fpm.conf"
        (prefix+'org.php-fpm.plist').write startup_plist
    end
  end

  def caveats
    c = <<-EOS
For 10.5 and Apache:
    Apache needs to run in 32-bit mode. You can either force Apache to start 
    in 32-bit mode or you can thin the Apache executable.

To enable PHP in Apache add the following to httpd.conf and restart Apache:
    LoadModule php5_module    #{prefix}/libexec/apache2/libphp5.so

The php.ini file can be found in:
    #{etc}/php/php.ini

'Fix' the default PEAR permissions and config:
    chmod -R ug+w #{prefix}/lib/php
    pear config-set php_ini #{etc}/php/php.ini
    EOS

    if ARGV.include? '--with-fpm'
      c += <<-FPMCAVEATS

You can start php-fpm automatically on login with:
    cp #{prefix}/org.php-fpm.plist ~/Library/LaunchAgents
    launchctl load -w ~/Library/LaunchAgents/org.php-fpm.plist
      FPMCAVEATS
    end

    return c
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.php-fpm</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
    <key>ProgramArguments</key>
    <array>
        <string>#{sbin}/php-fpm</string>
        <string>--fpm-config</string>
        <string>#{etc}/php/php-fpm.conf</string>
    </array>
    <key>WorkingDirectory</key>
    <string>#{HOMEBREW_PREFIX}</string>
  </dict>
</plist>
    EOPLIST
  end
end


__END__
diff -Naur php-5.3.2/ext/tidy/tidy.c php/ext/tidy/tidy.c 
--- php-5.3.2/ext/tidy/tidy.c	2010-02-12 04:36:40.000000000 +1100
+++ php/ext/tidy/tidy.c	2010-05-23 19:49:47.000000000 +1000
@@ -22,6 +22,8 @@
 #include "config.h"
 #endif
 
+#include "tidy.h"
+
 #include "php.h"
 #include "php_tidy.h"
 
@@ -31,7 +33,6 @@
 #include "ext/standard/info.h"
 #include "safe_mode.h"
 
-#include "tidy.h"
 #include "buffio.h"
 
 /* compatibility with older versions of libtidy */
diff --git a/sapi/fpm/php-fpm.conf.in b/sapi/fpm/php-fpm.conf.in
index 314b7e5..876e45e 100644
--- a/sapi/fpm/php-fpm.conf.in
+++ b/sapi/fpm/php-fpm.conf.in
@@ -22,7 +22,7 @@
 ; Pid file
 ; Note: the default prefix is @EXPANDED_LOCALSTATEDIR@
 ; Default Value: none
-;pid = run/php-fpm.pid
+pid = @EXPANDED_LOCALSTATEDIR@/run/php-fpm.pid
 
 ; Error log file
 ; Note: the default prefix is @EXPANDED_LOCALSTATEDIR@
@@ -56,7 +56,7 @@
 
 ; Send FPM to background. Set to 'no' to keep FPM in foreground for debugging.
 ; Default Value: yes
-;daemonize = yes
+daemonize = no
 
 ;;;;;;;;;;;;;;;;;;;;
 ; Pool Definitions ; 
@@ -154,17 +154,17 @@ pm.max_children = 50
 ; The number of child processes created on startup.
 ; Note: Used only when pm is set to 'dynamic'
 ; Default Value: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
-;pm.start_servers = 20
+pm.start_servers = 20
 
 ; The desired minimum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-;pm.min_spare_servers = 5
+pm.min_spare_servers = 5
 
 ; The desired maximum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-;pm.max_spare_servers = 35
+pm.max_spare_servers = 35
  
 ; The number of requests each child process should execute before respawning.
 ; This can be useful to work around memory leaks in 3rd party libraries. For
