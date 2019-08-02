#!/usr/bin/perl -w

@a=qw(1 2 3 4 5);
foreach(@a)
{
	print $_."\n";
	if($_==3)
	{ $_=9;}
}

print @a,"abc\n";
print "@a"."def\n";
