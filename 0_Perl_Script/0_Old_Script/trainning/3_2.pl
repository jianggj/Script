#!/usr/bin/perl -w

@name=qw(fred betty barney dino Wilma pebbles bamm-bamm);

chomp(@num=<STDIN>);

foreach $num(@num)
{
	print "the No.$num people name is : $name[$num-1]. \n";
	
}
