#!/bin/bash

key=private_key.pem
cert=certificate.pem
other_cert=other_certificate.pem

openssl rsa -in $key -des3 -out tmp_key.pem
openssl pkcs12 -export -in $cert -inkey tmp_key.pem -out keystore.p12

keytool -importkeystore -srckeystore keystore.p12 -srcstoretype pkcs12 -destkeystore keystore.jks -deststoretype JKS

keytool -import -alias other_certificate -keystore keystore.jks -file $other_cert

rm tmp_key.pem
rm keystore.p12
