#!/usr/bin/perl -w

chomp(@sort1=<STDIN>);

print "the string is : @sort1.\n";

@sort1=sort@sort1;
print "the new string one is : @sort1.\n";
foreach $s(@sort1)
{
	$s.="\n";
	print $s;
}
