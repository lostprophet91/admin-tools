#!/bin/bash
file_zone="/var/lib/bind/bcs.bull.net.hosts"
scope=$1
if test "$(echo $scope | egrep '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}')" = ""; then
  if test "$(echo $scope | grep ".bcs.bull.net")" = ""; then
    scope=$scope".bcs.bull.net"
  fi
fi
if test "$scope" = ""; then
  cat $file_zone | grep "IN" | egrep -v "RRSIG|NSEC|DNSKEY|SOA" | sort
else
  echo "Scope sur \"$scope\""
  cat $file_zone | grep $scope | grep "IN" | egrep -v "RRSIG|NSEC|DNSKEY|SOA" | sort
fi
echo
