#!/usr/bin/perl -w

use strict;

$^I=".out";

while(<>)
{
	chomp;
	s/fred/Larry/ig;
	print $_."\n";
	
}

