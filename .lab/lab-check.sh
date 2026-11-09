#!/usr/bin/env bash
rc=0
if [ -s stack.sh ] && ! grep -q 'TODO: write me' stack.sh && grep -q 'pw-pgdata' stack.sh && grep -q 'pw-backend' stack.sh; then echo "- ✅ stack.sh is written (volume and networks present)"
else echo "- ❌ stack.sh is still the starter or misses pw-pgdata / pw-backend"; rc=1; fi
if [ -s backup.sql ] && grep -q 'CREATE TABLE public.polls' backup.sql; then echo "- ✅ backup.sql is a pg_dump of the Pollie database"
else echo "- ❌ backup.sql must be a pg_dump of the Pollie database"; rc=1; fi
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
