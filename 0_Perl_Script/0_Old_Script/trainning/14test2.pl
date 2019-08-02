#!/usr/bin/perl -w

$n=1;
foreach $k(sort keys %ENV)
{
	print "[NO. $n]$k => $ENV{$k}\n";
	$n++;
}
