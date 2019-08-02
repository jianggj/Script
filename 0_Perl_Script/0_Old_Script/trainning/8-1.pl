#!/usr/bin/perl

while(<>)
{
	chomp;
	if(/match/)
	{
		print "Matched: |$` < $& > $'| \n";
	}else
	{
		print "no match:|$_|\n";
	}
	
}
