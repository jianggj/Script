#!/usr/bin/perl

use File::Spec;
use Cwd;
@PATH = File::Spec->path();
foreach(@PATH)
{
	print $_."\n";
}

my $t=getcwd();
print $t."\n";
