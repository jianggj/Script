#!/usr/bin/perl -w

use File::Spec;
use Cwd;

my $dir=getcwd();

my @file=glob "*";
my $fn=\@file;
foreach(@$fn)
{
	$a=File::Spec->catfile($dir,$_);
	print "$a\n";

}

