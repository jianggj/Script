#!/usr/bin/perl -w

use strict;

sub total()
{
	my @total=@_;
	my $a=0;
	foreach (@total)
	{
		 $a+=$_;
	}
   return $a;
}

my @fred =qw{1 3 5 7 9};
my $fred_total=&total(@fred);
print "the total of \@fred is $fred_total.\n";

print "Enter some numbers :\n";
my $user_total=&total(<STDIN>);
print "the total of those number is $user_total.\n";
