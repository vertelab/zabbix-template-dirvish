#!/usr/bin/perl -w 

###############################################################################
#ORIGINAL INFO
###############################################################################

# rdiff_check.pl v0.03  #
#
# This is a plugin for nagios to check the status of an rdiff-backup repository.
# Written by Christian Marie from Solutions First
# email christian@solutionsfirst.com.au for support
#
# Licensed under the GNU GPLv2 which google will find a copy of
# for you. 
# 
#
# For nagios you would simply stick a similar command in checkcommands or services and go from there.
# You should check it works from the commandline first.

#############################################################################
#NEW INFO
#############################################################################


# This is rewritten plugin for zabbix to check and collect statistics of
# an DIRVISH-backup repository.


use strict;
use File::stat;
use Getopt::Std;
use File::Basename;

sub usage();
sub print_results();
sub running();
my @date;
my @mir_list;
my $repository;
my %opts=();
my $time_stamp;
my $no_mir;
my $stats_fn;
my $elapsed;
my $cur_mir;
my @hour;
my $pid_1;
my $pid_2;
my $size_now;
my $size_change;
my $debug;
my $debug_show;
#my $err = 0;
my $command = "";

my $result;

usage if(!@ARGV);

if (!getopts( "r:d:c:", \%opts ))
{
  print "ERROR: getopts failed!";
  exit 1;
}

if(exists($opts{d})){
  if($opts{d} eq "yes"){
    $debug_show = 1;
  }
}

if( exists($opts{c})){
  $command = $opts{c};
}

if($<)
{
	$debug .= "ERROR: Must run as root\n";
	$result = "0";
	print_results();
	exit(3);
}

$repository = "$opts{r}/rdiff-backup-data";

if($command eq ""){
	print "ERROR: Invalid \"COMMAND\"\n";
	usage;
	exit(6);
}

@mir_list = <$repository/current_mirror*>;
$no_mir = scalar @mir_list;

if($no_mir == 1)
{
	$cur_mir = <$repository/current_mirror*>;
	($time_stamp) = ($mir_list[0] =~ /current_mirror\.(.*)\.data$/);
	$stats_fn = "$repository/session_statistics.$time_stamp.data";

	if(!-f $stats_fn)
	{
		$debug .= "ERROR: No session statistics file, deleted?\n";
		$result = "0";
		print_results();
		exit(3);
	}

	if($command eq "ts" or $command eq "cs"){

	    if(!open(FILE, "< $stats_fn"))
	    {
		$debug .= "ERROR: Could not open stat file\n";
		$result = "0";
		print_results();
		exit(3);
	    }

	    <FILE>;<FILE>;<FILE>;<FILE>;
	    $size_now = <FILE>;
	    ($size_now) = $size_now =~ /SourceFileSize (.*) \(.*\)$/;

	    <FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;
	    ($size_change) = <FILE> =~ /TotalDestinationSizeChange (.*) \(.*\)$/;
	
	    #$size_change = int($size_change /= 1048576);
	
	}
	
	if($command eq "st"){
	
	    $debug .= "stats - starttime (cca) \n";
	    $result = localtime(stat($cur_mir)->mtime);
	    print_results();
	
	}
	elsif($command eq "stt"){
	
	    $debug .= "stats - starttime timestamp (cca) \n";
	    $result = stat($cur_mir)->mtime;
	    print_results();
	}
	elsif($command eq "ts"){
	
	    #$size_now = int($size_now /= 1048576);
	
	    $debug .= "Total size...\n";
	    $result = $size_now;
	    print_results();
	}
	elsif($command eq "cs"){
	
	    $debug .= "Change size...\n";
	    $result = $size_change;
	    print_results();
	}
	elsif($command eq "status"){
	
	    $elapsed = localtime(stat($stats_fn)->mtime);
	
	    $debug .= "OK: Last backup finished ".$elapsed."\n";
	    $result = "1";
	    print_results();
	}

	exit(0);

}

if($no_mir == 2)
{
	open(FILE,"< $mir_list[0]");
	$pid_1 = <FILE>;
	
	if(!defined $pid_1)
	{
		$debug .= "CRITICAL: Really broken repository\n";
		$result = "0";
		print_results();
		exit(3);
	}
	
	chomp($pid_1);
	($pid_1) = ($pid_1 =~ /PID (.*)$/);
   
	open(FILE,"< $mir_list[1]");
	$pid_2 = <FILE>;
	chomp($pid_2);
	($pid_2) = ($pid_2 =~ /PID (.*)$/);
	
	if(!defined $pid_2)
	{
		$debug .= "CRITICAL: Really broken repository\n";
		$result = "0";
		print_results();
		exit(2);
	}

	if(-f "/proc/$pid_1/cmdline")
	{
		if(!open(FILE, "< /proc/$pid_1/cmdline"))
		{
			$debug .= "ERROR: Couldn't open cmdline file, permissions?\n";
			$result = "0";
			print_results();
			exit(3);
		}
		$pid_1 = <FILE>;
		running() if ($pid_1 =~ /rdiff-backup/);
	}
	
	if(-f "/proc/$pid_2/cmdline")
	{
		if(!open(FILE, "< /proc/$pid_2/cmdline"))
		{
			$debug .= "ERROR: Couldn't open cmdline file, permissions?\n";
			$result = "0";
			print_results();
			exit(3);
		}
		$pid_2 = <FILE>;
		running() if ($pid_2 =~ /rdiff-backup/);
	}
	
	$debug .= "CRITICAL: Backup interrupted\n";
	$result = "0";
	print_results();
	exit(2);
}

$debug .= "ERROR: Neither one current mirror, nor two\n";
$result = "0";
print_results();
exit(3);

sub running()
{
	$cur_mir = <$repository/current_mirror*>;
	($time_stamp) = ($mir_list[0] =~ /current_mirror\.(.*)\.data$/);
	$stats_fn = "$repository/session_statistics.$time_stamp.data";
#	$elapsed = ((time() - $cron_cycle) - stat($stats_fn)->mtime);
#	if($elapsed > 0)
#	{
#		@hour = localtime(time());
#		if($hour[2] >= $c_thresh)
#		{
#			print "CRITICAL: Backup still running after $c_thresh:00\n";
#			exit(2);
#		}
#		if($hour[2] >= $w_thresh)
#		{
#			print "WARNING: Backup running after $w_thresh:00\n";
#			exit(1);
#		}
#	}
	
	print "OK: Backup in progress\n";
	exit(0);
}

sub print_results(){

	if($command eq "status"){
	    print $result . "\n";
	}
	elsif($command eq "st" or $command eq "ts" or $command eq "cs" or $command eq "stt"){
	    print $result . "\n";
	}
	else{
	    print "ERROR: Unknown \"command\" \n";
	}
	
	if($debug_show){
	    print $debug;
	}

}

sub usage()
{
	print "Usage: rdiff_backup_stats.pl [OPTIONS] [COMMAND]\n
      OPTIONS:
	-r <rdiff repository>
	-d <yes|no>
	-c <command>\n
      COMMANDS:
	status <status of backup>
	cs <change size>
	ts <total size>
	st <start time>
	stt <start time timestamp>"
	.">\n";
	exit(3);
}
