#!/usr/bin/perl -w
use strict;
use warnings;

print("start\n");
my $i;
foreach $i (1 .. 100000)
{

  print("\rNo.$i line start!");
}

print("\nfinish\n");
