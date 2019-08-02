#!/usr/bin/perl

while(<>)
{
	chomp;
	if(/(\w*a\b)/)
	{
		print "Matched: [$`|$&|$']\n";
		print "The \$1:\'$1\'\n";
		printf "This is [%.5s]\n",$';
	}
	
}
