#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;


my $verbose;
my $password;
my $private_key;
my @certificates;

my $result = GetOptions(
    'v|verbose'  => \$verbose,
    'private-key=s' => \$private_key,
    'certificate=s' => \@certificates,
    'password=s' => \$password,
);
