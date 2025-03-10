#!/bin/bash
sed -i 's/\-include_lib(\"kernel\/include\/logger.hrl\")\./-include_lib\(\"kernel\/include\/logger.hrl\"\)\.\n-include\(\"tuplelog/include/tuplelog.hrl\"\)\./g' *.erl

echo "duplicates created:"
grep -c tuplelog.hrl *.erl | grep ":2" 
