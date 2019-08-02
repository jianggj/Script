#!/usr/bin/perl

while(<>)
{
	chomp;
	if(/\s$/)
	{
		print "Matched: $`<$&>\n";
	}else
	{
		print "NO Matched!\n";
		
	}
	
}
