#!/usr/bin/env perl
# FILENAME: aggregate_good.pl
# CREATED: 07/28/14 00:00:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Aggregate the "good" list to a superlist

use strict;
use warnings;
use utf8;

use JSON;
use Path::Tiny qw( path );
use List::UtilsBy qw( uniq_by );

my $json = JSON->new()->pretty->canonical;

my @all;

for my $child ( path('./good/')->children ) { 
  push @all, @{ $json->decode(scalar $child->slurp_raw )->{users} };
}
my @out = sort { $b->{followers_count} <=> $a->{followers_count} } uniq_by { $_->{id} } @all;

path('./all_followers_over_70.json')->spew_raw( $json->encode(\@out ));
path('./all_followers_over_70_perl.json')->spew_raw( $json->encode([ grep { length $_->{language} and $_->{language} eq 'Perl' } @out ]) );
