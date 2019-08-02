#!/usr/bin/perl -w
use File::Basename;

eval{
@t=`perl 15-2.pl`;
$c=\@t;
foreach(@$c)
{
	$name=basename($_);
	print "$name";
}
};

if(1) {print "aas\n";}
