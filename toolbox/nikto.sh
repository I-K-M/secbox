#!/bin/sh
set -eu
exec perl /opt/nikto/nikto.pl -config /opt/nikto/nikto.conf -nocheck "$@"
