#!/usr/bin/perl

$n=int(1 + rand 1000);
print "1から１０００までの数値を入力してください:\n";

while(<>)
{
		chomp;
	if($_ eq ("exit"|"quit"|"\n"))
	{
		last;
	}elsif($_ < $n)
	{
		print "小さい!\n";	
	}elsif($_ > $n)
	{
		print "大きい!\n";
	}elsif($_ == $n)
	{
		print "正解!!\n";
		last;
	}else
	{ print "入力エラー!\n"; last;}
	print "…………………………………………………………\n";
	print "再入力してください:\n";
	
}
