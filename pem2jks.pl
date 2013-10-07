#!/usr/bin/perl

use strict;
use warnings;

use Expect;
use Getopt::Long;


$|=1;
$Expect::Log_Stdout = 0;


my $quiet;
my $password;
my $private_key;
my @certificates;

my $result = GetOptions(
    'q|quiet'  => \$quiet,
    'k|private-key=s' => \$private_key,
    'c|certificate=s' => \@certificates,
    'p|password=s' => \$password,
);

unless ((defined $private_key) and (-e $private_key) and
        (scalar(@certificates) > 0) and (-e $certificates[0]) and
        length($password) >= 6 and scalar(@ARGV) == 1
) {
    print "Usage: ./pem2jks.pl -p password -k /path/to/private_key.pem "
        ."-c /path/to/certificate.pem [-c /path/to/other/certificates.pem] output-filename\n";
    exit 1;
}

my $output_file = $ARGV[0];

my $command;
my $exp;


$quiet or print "Setting password for private key...";

$command = "openssl rsa -in $private_key -des3 -out tmp_key.pem";

$exp = Expect->spawn($command);
$exp->expect(
    1,
    ['Enter PEM pass phrase:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Verifying - Enter PEM pass phrase:' => sub { shift->send($password."\n"); exp_continue; }],
);
$exp->soft_close();

$quiet or print "done!\n";


$quiet or print "Creating pkcs12 keystore with private key and first certificate...";

my $certificate = shift @certificates;
$command = "openssl pkcs12 -export -in $certificate -inkey tmp_key.pem -out keystore.p12";

$exp = Expect->spawn($command);
$exp->expect(
    1,
    ['Enter pass phrase for tmp_key.pem:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Enter Export Password:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Verifying - Enter Export Password:' => sub { shift->send($password."\n"); exp_continue; }],
);
$exp->soft_close();

$quiet or print "done!\n";


$quiet or print "Converting pkcs12 keystore to Java keystore...";

$command = "keytool -importkeystore -srckeystore keystore.p12 "
    ."-srcstoretype pkcs12 -destkeystore $output_file -deststoretype JKS";

$exp = Expect->spawn($command);
$exp->expect(
    1,
    ['Enter destination keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Re-enter new password:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Enter source keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
);
$exp->soft_close();

$quiet or print "done!\n";


foreach my $certificate (@certificates) {
    $quiet or print "Importing $certificate...";
    my $alias = $certificate;

    $command = "keytool -import -keystore $output_file -file $certificate";

    $exp = Expect->spawn($command);
    $exp->expect(
        1,
        ['Enter keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
        [qr/Trust this certificate\?/, sub { shift->send("yes\n"); exp_continue; }],
    );
    $exp->soft_close();

    $quiet or print "done!\n";
}

`rm tmp_key.pem keystore.p12`;
