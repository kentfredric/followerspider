#!/usr/bin/env perl
# FILENAME: fetch_followers.pl
# CREATED: 07/27/14 20:47:08 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Get raw follower data

use strict;
use warnings;
use utf8;

use Path::Tiny qw( path );
use HTTP::Tiny;
use Data::Dump qw( pp );

my $min_followers = 10;
my $max_pages     = 10;

my ( $token, ) = path('./gh_token.txt')->lines_raw( { chomp => 1 } );

my $ua = HTTP::Tiny->new(
    default_headers => {
        'Authorization' => 'token ' . $token,
    },
);
use JSON;
my $json = JSON->new();

my $udata = path('./users/');

my @ranges = (

    # tested
    '>1000',
    '500..1000',
    '400..500',
    '300..400',
    '200..300',
    '166..200',
    '133..166',
    '120..133',
    '110..120',
    '100..110',
    '95..100',
    '90..95',
    '85..90',
    '80..85',
    '75..80',
    '70..75',

    # more than 10 pages each
    #    '50..60',
    #    '40..50',
    #    '30..40',
    #    '20..30',
);

$udata->mkpath;

range: for my $range (@ranges) {
  page: for my $page ( 0 .. 10 ) {
        my $store_file = $udata->child( $range . '_' . $page . '.json' );

      fc: {
            $store_file->remove;

            print "Fetching page $page of $max_pages for $range\n";

            my $response = $ua->mirror(
"https://api.github.com/legacy/user/search/followers:$range?sort=followers&order=desc&start_page=${page}",
                $store_file->stringify
            );

            pp( [ $response->{headers}, $response->{status} ] );

            if ( $response->{status} eq '403' ) {
                while ( time < $response->{headers}->{'x-ratelimit-reset'} ) {
                    printf "403 :( Penalised till %s ( now %s )\n",
                      scalar
                      localtime( $response->{headers}->{'x-ratelimit-reset'} ),
                      scalar localtime;
                    sleep 10;
                }
                next fc;
            }
            if ( 0 == $response->{headers}->{'x-ratelimit-remaining'} ) {
                while ( time < $response->{headers}->{'x-ratelimit-reset'} ) {
                    printf "Ratelimit 0 :( Penalised till %s ( now %s )\n",
                      scalar
                      localtime( $response->{headers}->{'x-ratelimit-reset'} ),
                      scalar localtime;
                    sleep 10;
                }
                next page;
            }
            my $ds = $json->decode( $store_file->slurp_raw );
            next range if not @{ $ds->{users} };

            sleep 1;
        }
    }
}

