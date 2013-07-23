#!/usr/bin/perl

use strict;
use warnings;

use Expect;
use Getopt::Long;


$|=1;
$Expect::Log_Stdout = 0;


my $verbose;
my $password;
my $private_key;
my @certificates;

my $result = GetOptions(
    'v|verbose'  => \$verbose,
    'k|private-key=s' => \$private_key,
    'c|certificate=s' => \@certificates,
    'p|password=s' => \$password,
);


my $command;
my $exp;


print "Setting password for private key...";

$command = "openssl rsa -in $private_key -des3 -out tmp_key.pem";

$exp = Expect->spawn($command);
$exp->expect(
    1,
    ['Enter PEM pass phrase:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Verifying - Enter PEM pass phrase:' => sub { shift->send($password."\n"); exp_continue; }],
);
$exp->soft_close();

print "done!\n";


print "Creating pkcs12 keystore with private key and first certificate...";

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

print "done!\n";


print "Converting pkcs12 keystore to Java keystore...";

$command = "keytool -importkeystore -srckeystore keystore.p12 "
    ."-srcstoretype pkcs12 -destkeystore keystore.jks -deststoretype JKS";

$exp = Expect->spawn($command);
$exp->expect(
    1,
    ['Enter destination keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Re-enter new password:' => sub { shift->send($password."\n"); exp_continue; }],
    ['Enter source keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
);
$exp->soft_close();

print "done!\n";


foreach my $certificate (@certificates) {
    print "Importing $certificate...";
    my $alias = $certificate;

    $command = "keytool -import -alias $alias -keystore keystore.jks -file $certificate";
    $command = "keytool -import -keystore keystore.jks -file $certificate";

    $exp = Expect->spawn($command);
    $exp->expect(
        1,
        ['Enter keystore password:' => sub { shift->send($password."\n"); exp_continue; }],
        [qr/Trust this certificate\?/, sub { shift->send("yes\n"); exp_continue; }],
    );
    $exp->soft_close();

    print "done!\n";
}

`rm tmp_key.pem keystore.p12`;
