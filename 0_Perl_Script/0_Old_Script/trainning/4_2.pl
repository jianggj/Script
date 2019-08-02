#!/usr/bin/perl -w

use strict;

sub total()
{
	my $total=@_;
	my $a=0;
	foreach (@total)
	{
		 $a+=$_;
	}
   return $a;
}

my @aNum=1..1000;
my $aNum_total=&total(@aNum);
print "the total of 1~1000 is :$aNum_total.\n";
