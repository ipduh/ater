# g0 ,2018
# ater/aterlib.pl

use v5.10;
our $ME;
our $serial;
my $ADB = "adb $serial";

our %CONF;
my $DROZER = $CONF{'DROZER'};
my $IP = $CONF{'IP'};
my $PORT = $CONF{'PORT'};

sub say_command
{
  my ($command, $color) = @_;
  say "$ME: $command";
  my @in = `$ADB shell "${command}"`;
  my $st = $?;
  our $SAY_COM_COUNT++ if($st == 0);
  print for(@in);
  return $st;
}

sub say_ct
{
  my $command = shift;
  say "$ME: $command";
  my @in = `$ADB shell "${command}"`;
  my $st = $?;
  $SAY_COM_COUNT++ if($st == 0);
  print for(@in);
  return @in;
}

sub who_android_app
{
 my $app = shift;
 say_command("$DROZER console connect $IP:$PORT -c 'run app.package.attacksurface -a $app'");
 say_command("$DROZER console connect $IP:$PORT -c 'run app.package.info -a $app'");
 say_command("$DROZER console connect $IP:$PORT -c 'run app.provider.info -a $app'");
}

sub who_android_service
{
  my ($service, @nicks) = @_;

  my $nicks = ''; $nicks.="|${_}" for(@nicks);

  my @in = say_ct("grep 'service $service' /*rc");
  my @files = ();
  for(@in){
    chomp;
    my @fields = split(':', $_);
    $fields[0] =~ s/\///g;
    push(@files,$fields[0]);
  }
  my $files_s = '';
  $files_s.="${_}," for(@files);
  $files_s =~ s/,$//;

  say_command("egrep -in '$service${nicks}|proper' -A2 /{$files_s}");
  # With “--early” set, the init executable will skip mounting entries with “latemount” flag and triggering fs encryption state event.
  say_command("egrep 'early|late|mount|setprop' -A4 /{$files_s}");

  say_command("egrep -in '$service|shared-user$nicks' /data/system/packages.xml");
  say_command("ls -l /proc/[0-9]*/fd/* 2>/dev/null |egrep '$service$nicks' 2>/dev/null");

  say_command("ls -l /{system,vendor,odm}/etc/init");
  say_command("ls -l /{vendor,system}/bin |egrep -i '$service$nicks'");
  say_command("ls -l /{vendor,system}/lib{,64} |egrep -i '$service$nicks'");

  # find /dev -type s |grep -i $service |xargs ls -lZ
  say_command("ls -lZ - /dev/socket |grep -i $service");
  # socat -T 10 -dd -D UNIX:$_ - for(/dev/*ril*)
  # socat -T 10 -dd -D UNIX-CONNECT:/dev/socket/qmux_radio/qcril_radio_config0 -

  say_command("netstat -n |egrep -i '$service$nicks'");
  say_command("ip a");

  # say_command("dumpsys -t 10 -l |egrep -i 'carrier|phone|radio|modem|ril|tel'");
  my @srvs = say_ct("dumpsys -t 10 -l |egrep -i '$service$nicks'");
  for(@srvs){
    say_command("dumpsys -t 5 $_");
  }
  # say_command("dumpsys -t 5 telephony.registy media.radio telecom");
  # find processes that make use of ashmem
  # toybox ls -l /proc/[0-9]*/fd/* 2>/dev/null |grep /dev/ashmem |tr -s ' ' |cut -d' ' -f8 |cut -d/ -f3 |sort |uniq
  #
}


sub who_radio
{
  say_command("egrep -i 'radio|appv|phone' /proc/kallsyms");
}

sub who_android_system
{
  say_command("setenforce 0;getenforce");
  say_command("echo 1 > /sys/kernel/debug/kprobes/enabled");
  say_command("cat /sys/kernel/debug/kprobes/enabled");
  say_command("cat /sys/kernel/debug/kprobes/list");
  say_command("lsmod");
  say_command("echo 1 > /dev/hwlog_switch");
  say_command("cat /dev/hwlog_switch");
  say_command("cat /sys/kernel/debug/debug_enabled");
  say_command("ls /sys/kernel/debug");

  # /data/local.prop
  say_command("getprop ro.debuggable");

  say_command("setprop kmleak.debug 1");
  say_command("setprop debug.aps.enable 1");
  say_command("setprop persist.sys.huawei.debug 1");
  say_command("setprop persist.sys.kmemleak.debug 1");
  say_command("setprop debug.atrace.tags.enableflags 1");
  say_command("getprop |egrep 'adb|secure|kernel|debug|kmleak'");
  say_command("toybox ps -AlwZ |grep -i debug");
  say_command("toybox ls -R /config");

  say_command("grep Proc /proc/cpuinfo");
  say_command("cat /proc/cpuinfo |grep CPU |sort |uniq");
  say_command("cat /proc/meminfo");

  # say_command("ls -l /etc/init");
  say_command("cat /init.rc");
  my @imports = say_ct("grep import /init.rc");

  say_command("egrep 'cmdline|default\.prop'  /init.rc");
  say_command("egrep 'kernel.*debug'  /init.rc");

  say_command("cat /proc/sys/kernel/randomize_va_space");
  say_command("grep randomize_va_space /init.rc");

  #  If kptr_restrict is set to 0, no deviation from the standard %p behavior
  #  occurs.  If kptr_restrict is set to 1, if the current user (intended to
  #  be a reader via seq_printf(), etc.) does not have CAP_SYSLOG (which is
  #  currently in the LSM tree), kernel pointers using %pK are printed as
  #  0's.  If kptr_restrict is set to 2, kernel pointers using %pK are
  #  printed as 0's regardless of privileges.  Replacing with 0's was chosen
  #  over the default "(null)", which cannot be parsed by userland %p, which
  #  expects "(nil)".
  say_command("cat /proc/sys/kernel/kptr_restrict");
  say_command("grep kptr_restrict /init.rc");
  # show kernel pointers
  say_command("echo 0 > /proc/sys/kernel/kptr_restrict");

  # Changes can also be automatically applied on upgrade to other partitions by adding restorecon_recursive calls
  # to your init.board.rc file after the partition has been mounted read-write
  say_command("grep 'restorecon_recursive'  /init.rc");

  say_command("cat  /init.rc");

  say_command("grep mount_all /*rc");

  say_command("cat /vendor/build.prop");
  # say_command("getprop |grep ro");
  # say_command("ls -l /dev/block/platform/*/by-name 2>/dev/null");
  say_command("find /{system,vendor}/bin -perm -4000 -o -perm -2000 -exec ls -lZ {} \\;");
  #don't or with above
  say_command("find /{system,vendor}/bin -perm -2 -exec ls -lZ {} \\;");
  say_command("find /dev/socket -perm -4000 -o -perm 2000 -o -perm -2 -exec ls -lZ {} \\;");
  say_command("find /dev -perm -2 -exec ls -lZ {} \\;");
  say_command("find /dev/ -type c -a -user root -o -user radio -type c -exec ls -lZ {} \\;");
  say_command("cat /proc/net/{ptype,protocols}");
  say_command("toybox netstat -paneW |grep LISTEN");
  say_command("toybox netstat -punta");

  #abstract namespace sockets
  say_command("grep '\@' /proc/net/unix");

  # for cat /proc/net/netlink
  #   $_, pid, inode

  #lsof |grep logcat |grep data

  # ls /sys/bus/usb/drivers
  # lsusb ...
  # grep usb /*rc |cut -d: -f1 |cut -d/ -f2 |sort |uniq

  say "$ME: Processes that make use of ashmem";
  my @pids = `$ADB shell "toybox ls -l /proc/[0-9]*/fd/* 2>/dev/null |grep /dev/ashmem |tr -s ' ' |cut -d' ' -f8 |cut -d/ -f3 |sort |uniq"`;
  my $pids = '';
  for(@pids){
    chomp $_;
    $pids.="${_},"
  }
  say_command("toybox ps -Mw -p $pids -n -o USER,UID,TTY,PID,RUID,RGID,RSS,ADDR,CMD,COMM,F,GROUP,MAJFL,NAME,PCPU,S,STIME,VSZ,WCHAN,ETIME,LABEL,NI,PSR");
  say_command("toybox ps -Mw -p $pids -n -o UID,PID,NAME,WCHAN,PCPU");
}

sub explore_pid
{
  my $NONE = 'none'; #stupid
  my ($name, $pid, @nicks) = @_;
  my $ADB = "adb $serial";

  unless(length $pid){
    say_command("ps |grep $name");
    # my @getprop = `$ADB shell getprop`;
    # for(@getprop){ print "\t$_" if(/$name/i); }
    say_command("getprop |grep -i $name");
    $pid = `$ADB shell pgrep rild`; chomp $pid;
  }

  if($pid =~ /\d{1,9}/){
    say_command("toybox ps -MlwZ -p $pid");
    say_command("ls -l /proc/$pid/{root,cwd,exe}");
    say_command("dumpsys meminfo $pid");

    my $pid_environ = `$ADB shell "cat /proc/$pid/environ"`;
    say_command("cat /proc/$pid/environ");
    my @environ_ = split('=', $pid_environ);
    my %pid_environ = ();
    my $next_label = 'PATH';
    my $var = '';
      for(@environ_){
        /( [A-Z_]{3,} )/xg;
        my $M = $1;
        my @edges = split(/$M/, $_);
        $var = $edges[0];
        if(length $var){
          $pid_environ{"$next_label"} = $var;
        }else{
          $pid_environ{"$next_label"} = $_;
        }
        if(/( [A-Z_]+ )$/xg){
          $next_label = $1;
        }else{
          $next_label = "${M}$edges[1]";
        }
        #it does not handle ANDROID_STORAGE=EXTERNAL_STORAGE=/sdcard
      }
      for my $key (keys %pid_environ){
        say "\t$key";
        say "\t$pid_environ{$key}";
        say '';
      }
      my @maps = `$ADB shell "cat /proc/$pid/maps"`;
      say_command("cat /proc/$pid/maps |grep -i $name") unless($name eq $NONE);
      my @libs = ();
      my @properties = ();
      my $lib = 'lib';
      my $properties = 'properties';
      for(@maps){
        chomp;
        my @fields = split;
        for(@fields){
          chomp;
          if(/$lib/){
          push @libs, $_;
        }
        if(/$properties/){
          push @properties, $_ if(/$properties/);
        }
      }
      }
      say "$ME: $name libraries";
      say "$_" for(uniq(@libs));
      say;
      say "$ME: $name properties";
      say "$_" for(@properties);
      say;
      say_command("cat /proc/$pid/status");
      say_command("ls -l /proc/$pid/fd");
      say_command("toybox ls -l /proc/$pid/fd/* 2>/dev/null |grep /dev/ashmem");

      say_command("cat /proc/$pid/net/unix |grep -i $name") unless($name eq $NONE);
      # say_command("cat /proc/$pid/net/dev");
      say_command("cat /proc/$pid/net/udp");
      say_command("cat /proc/$pid/net/tcp");
      say_command("toybox lsof -p $pid");

      # enumerate threads
      #say_command("for i in `ls /proc/$pid/task`;do echo -n \$i ;grep Name /proc/$pid/task/\$i/status; done");
      say_command("grep Name /proc/$pid/task/*/status");

      # am dumpheap $pid /data/local/tmp/dumpheap.${pid}.log
      # pull log ...
    }
}

1;
