#!/usr/bin/perl

# Zabbix 2 - disk autodiscovery for linux
# all dirvish-backup's repositories/folders are returned

# Discovery items creation :
#T.B.D.


sub loadconfig;

$Options = 
{ 
	help		=> \&usage,
	version		=> sub {
			print STDERR "dirvish version $VERSION\n";
			exit(0);
		},
};

loadconfig(undef, "/etc/dirvish/master.conf", $Options);
print $$Options{'bank'};

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



sub seppuku	# Exit with code and message.
{
	my ($status, $message) = @_;

	chomp $message;
	if ($message)
	{
		$seppuku_prefix and print STDERR $seppuku_prefix, ': ';
		print STDERR $message, "\n";
	}
	exit $status;
}

sub slurplist
{
	my ($key, $filename, $Options) = @_;
	my $f;
	my $array;

	$filename =~ m(^/) and $f = $filename;
	if (!$f && ref($$Options{vault}) ne 'CODE')
	{
		$f = join('/', $$Options{Bank}, $$Options{vault},
			'dirvish', $filename);
		-f $f or $f = undef;
	}
	$f or $f = "$CONFDIR/$filename";
	open(PATFILE, "<$f") or seppuku 229, "cannot open $filename for $key list";
	$array = $$Options{$key};
	while(<PATFILE>)
	{
		chomp;
		length or next;
		push @{$array}, $_;
	}
	close PATFILE;
}


sub loadconfig
{
	my ($mode, $configfile, $Options) = @_;
	my $confile = undef;
	my ($key, $val);
	my $CONFIG;
	ref($Options) or $Options = {};
	my %modes;
	my ($conf, $bank, $k);

	$modes{r} = 1;
	for $_ (split(//, $mode))
	{
		if (/[A-Z]/)
		{
			$_ =~ tr/A-Z/a-z/;
			$modes{$_} = 0;
		} else {
			$modes{$_} = 1;
		}
	}


	$CONFIG = 'CFILE' . scalar(@{$$Options{Configfiles}});

	$configfile =~ s/^.*\@//;

	if($configfile =~ m[/])
	{
		$confile = $configfile;
	}
	elsif($configfile ne '-')
	{
		if(!$modes{g} && $$Options{vault} && $$Options{vault} ne 'CODE')
		{
			if(!$$Options{Bank})
			{
				my $bank;
				for $bank (@{$$Options{bank}})
				{
					if (-d "$bank/$$Options{vault}")
					{
						$$Options{Bank} = $bank;
						last;
					}
				}
			}
			if ($$Options{Bank})
			{
				$confile = join('/', $$Options{Bank},
					$$Options{vault}, 'dirvish',
					$configfile);
				-f $confile || -f "$confile.conf"
					or $confile = undef;
			}
		}
		$confile ||= "$CONFDIR/$configfile";
	}

	if($configfile eq '-')
	{
		open($CONFIG, $configfile) or seppuku 221, "cannot open STDIN";
	} else {
		! -f $confile && -f "$confile.conf" and $confile .= '.conf';

		if (! -f "$confile")
		{
			$modes{o} and return undef;
			seppuku 222, "cannot open config file: $configfile";
		}

		grep(/^$confile$/, @{$$Options{Configfiles}})
			and seppuku 224, "ERROR: config file looping on $confile";

		open($CONFIG, $confile)
			or seppuku 225, "cannot open config file: $configfile";
	}
	push(@{$$Options{Configfiles}}, $confile);

	while(<$CONFIG>)
	{
		chomp;
		s/\s*#.*$//;
		s/\s+$//;
		/\S/ or next;
		
		if(/^\s/ && $key)
		{
			s/^\s*//;
			push @{$$Options{$key}}, $_;
		}
		elsif(/^SET\s+/)
		{
			s/^SET\s+//;
			for $k (split(/\s+/))
			{
				$$Options{$k} = 1;
			}
		}
		elsif(/^UNSET\s+/)
		{
			s/^UNSET\s+//;
			for $k (split(/\s+/))
			{
				$$Options{$k} = undef;
			}
		}
		elsif(/^RESET\s+/)
		{
			($key = $_) =~ s/^RESET\s+//;
			$$Options{$key} = [ ];
		}
		elsif(/^[A-Z]/ && $modes{f})
		{
			$key = undef;
		}
		elsif(/^\S+:/)
		{
			($key, $val) = split(/:\s*/, $_, 2);
			length($val) or next;
			$k = $key; $key = undef;

			if ($k eq 'config')
			{
				$modes{r} and loadconfig($mode . 'O', $val, $Options);
				next;
			}
			if ($k eq 'client')
			{
				if ($modes{r} && ref ($$Options{$k}) eq 'CODE')
				{
					loadconfig($mode .  'og', "$CONFDIR/$val", $Options);
				}
				$$Options{$k} = $val;
				next;
			}
			if ($k eq 'file-exclude')
			{
				$modes{r} or next;

				slurplist('exclude', $val, $Options);
				next;
			}
			if (ref ($$Options{$k}) eq 'ARRAY')
			{
				push @{$$Options{$k}}, $_;
			} else {
				$$Options{$k} = $val;
			}
		}
	}
	close $CONFIG;
	return $Options;
}
