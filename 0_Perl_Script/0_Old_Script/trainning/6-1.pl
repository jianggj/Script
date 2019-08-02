#!/usr/bin/perl

my %hNamelist=(
	"a"=>1,
	"b"=>2,
	"c"=>3,
	"d"=>4,
	"e"=>5,
);

print "Enter \"a\" to \"e\" :\n";
chomp($sInput=<STDIN>);

print "the value of $sInput is $hNamelist{$sInput}.\n"
