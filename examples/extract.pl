#!/usr/bin/perl

use strict;
use Text::ExtractWords qw(words_count);

my $file = $ARGV[0] or die("no file");


my %hash = ();
open(FILE, "<$file") or die("$!");
while(<FILE>) {
	words_count(\%hash, $_);
}
close(FILE);

while(my ($k, $v) = each(%hash)) {
	print "$k => $v\n";
}

exit();
