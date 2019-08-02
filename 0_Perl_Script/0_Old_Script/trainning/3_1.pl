#!/usr/bin/perl -w

chomp(@lines=<STDIN>);

print "this is lines:@lines\n";

@lines=reverse @lines;

print "this is the reverse: @lines\n";
