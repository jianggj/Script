#!/usr/bin/perl -w

use strict;

$^I=".[9-3bak]";

while(<>)
{
	chomp;
	s/fred/!!!!!/ig;
	s/wilma/Fred/ig;
	s/!!!!!/Wilma/ig;
	print $_."\n";
	
}

