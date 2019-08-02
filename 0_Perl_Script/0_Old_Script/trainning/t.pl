#! /usr/bin/perl -w

my @words=qw(9 8 7 6 5 4 1);
my @str=qw{h f g b v c d a };
my @new=sort { $a <=> $b }@words;
my @new1=sort {$a cmp $b}@str;
foreach(@new)
{
	print $_." ";
}
print "\n";
foreach(@new1)
{ print $_." ";}
print "\n";
