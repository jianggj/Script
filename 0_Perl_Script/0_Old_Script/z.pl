#!/usr/bin/perl -w

use strict;

print "input:\n";
while(<>)
{
	if ($_=~/(?:[A-Z]\w*\s+([a-z]\w+))/)
	{print $&,"\n";}
}

