#!/usr/bin/perl

$PI=3.141592654;
#$r=12.5;

$r=<STDIN>;
if($r <= 0)
    {
	 print "周長は:0\n";
	}else{
			$L=2*$PI*$r;
			print "周長は:$L\n";
}
