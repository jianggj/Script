#!/usr/bin/perl
$what='fred|barney';

while(<>)
{
	chomp;
	if(/($what){3}/)
	{
		print "Matched: $` [$&] $'\n";
	}else
	{
		print "NO Matched!\n";
		
	}
	
}
