#!/bin/bash
/usr/sbin/smartctl --tolerance=permissive "$@"
exit_code=$?
exit $((exit_code & ~4))
