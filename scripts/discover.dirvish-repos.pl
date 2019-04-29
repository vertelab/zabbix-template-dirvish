#!/usr/bin/perl

# Zabbix 2 - disk autodiscovery for linux
# all dirvish-backup's repositories/folders are returned

# Discovery items creation :
#T.B.D.

$scan_folder = "/srv/backups";
$scan_prefix = "dirvish";

my @find_cmd = ("find", "$scan_folder/", "-maxdepth", "1", "-name", "$scan_prefix*", "-type", "d");

open FIND, "-|", @find_cmd;

my @files = <FIND>;
my $ret = close FIND or warn $! ?
    "Error closing find pipe: $!" :
        "find exited with non-zero exit status: $?";

#print join(", ", @files);
#print @files;

$first = 1;
print "{\n";
print "\t\"data\":[\n\n";

foreach(@files){

  $full_name = $_;
  $full_name =~ s/^\s+|\s+$//g;

  ($folder, $name) = split /$scan_prefix-/, $full_name;

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#NAME}\":\"".$name."\",\n";
  print "\t\t\"{#FULLNAME}\":\"".$full_name."\"\n";
  print "\t}\n";

} #end of foreach @files

print "\n\t]\n";
print "}\n";
