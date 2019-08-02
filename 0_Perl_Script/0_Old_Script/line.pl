use strict;

open FINISH,">>finish.csv";
my @line;
my $sqlid
while(<>)
{
	if(/^\t/)
	{
		my $l=__LINE__;
		push ($l,@line);
		$sqlid=$';
	}
    my $min=$line[0];
	my $max=$line[$#line];
	print FINISH "[$sqlid] $min,$max";
}


