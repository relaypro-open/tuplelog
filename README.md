tuplelog
=====

A collection of macros for the logger application that allows the use of tuples in log statements to provide both human readable and structured logging in one statement.  Works along with other log formatters (like flatlog, logger_formatter_json) to provide structured logging.

Why?
----
There is valid use for both structured logging and user scannable logs.
So why not do both?

Structured logging has huge advantages over human readable logs, mainly so log analysis tools like
ElasticSearch can query logs like a real database, but there are disadvantages also.
Human readable logs include the context - the relationship between different data that can be
more difficult to understand in structured logging.  

The log:

"X value of 100 is greater than threshold 80" 

states a relationship between X and N that has to be parsed in reverse with a structured log:

{"X": 100, "N": 80, "msg": "X exceeds threshold N"} 

or even lost:

{"X": 100, "N": 80, "msg": "threshold exceeded"}

In addition, human readable logs are more easily scanned while they are
tailed, taking advantage of human's great skill in finding patterns along with a developers
knowledge of what these logs actually mean.  tuple logs also allow the logging of the log statement templates, which provide a human comprehensible link between human readable logs and log analysis databases.

You could, for example, set up multiple handlers for:

- Structured logs, which are not stored locally, but are streamed to a log storage and analysis systems (like ELK): https://github.com/zotonic/logstasher
- Human readable logs that only exist locally, allowing local tailing

Structured Logging Tips
----
1) Use consistent naming of variables across functions: HostKey, host_key, hostkey, Key (pick one).
This will allow you to query the same data across multiple log statements.


Usage
-----

It is recommended that if you are providing a library, you do not add this
project as a dependency. A code formatter of this kind should be added to a
project in its release repository as a top-level final presentational concern.

Once the project is added, replace the formatter of the default handler (or add
a custom handler) for structured logging to your `sys.config` file:

```erlang
[
 {kernel, [
    {logger, [
        {handler, default, logger_std_h,
         #{formatter => {tupleog, #{
            map_depth => 3,
            term_depth => 50
          }}}
        }
    ]},
    {logger_level, info}
 ]}
].
```

Next, all files that will call the LOGT_* macros must include tuplelog.hrl:
```erlang
-include_lib("tuplelog/include/tuplelog.hrl").
```

Macros defined are analogs to the standard logger macros, but with a list of tuples as the second parameter:
```erlang
?LOG_INFO/2 -> ?LOGT_INFO/2
?LOG_ERROR/2 -> ?LOGT_ERROR/2
?LOG_DEBUG/2 -> ?LOGT_DEBUG/2
```

In addition the following functions are analogs to the standard io format functions, also with a list
of tuples as the second parameter:
```erlang
tuplelog:proplist_format/2 -> io:format/2 
tuplelog:proplist_lib_format/2 -> io_lib:format/2 
```

So this log entry:
```erlang
Result = "Test",
?LOG_INFO("Result: ~p", [Result])
)
```
would become:
```erlang
Result = "Test",
?LOGT_INFO("Result: ~p", [{result, Result}])
)
```

Will produce a map like this:

```erlang
#{"unstructured_log" => "result => \"Test\"", 
  "template_log" => "Result: \"$result\"",
  "result" => "Test"}
```

template_log simply prepends '$' to the key of the tuple and logs that instead of the value.  You
can then use this to search for thes log entries in ELK without having to remove data values.  This
is not guaranteed to be unique as the combination of MFA + line number, but if it isn't, add MFA
and/or line number and it will be ;)

If sent to the tuplelog log formatter, this use the value of unstructured_log to produce a standard formatted log entry like, along with the template_log:
```erlang
1970-12-12T00:01:20.286786+00:00 [info] <0.PID.0> module:function/arrity:line_number Result: Test
template_log="Result: $result"
```

It can also or instead be sent to a structured log formatter such as json_log_formatter:
```json
{"msg":{"unstructured_log": "result: \"Test\"", 
  "template_log": "Result: \"$result\"",
  "result": "Test"}, ,"file":"test.erl","gl":"<0.PID.0>","level":"info","line":70,"mfa":"test:function/arity","pid":"<0.PID.0>","report_cb":"fun logger:format_otp_report/1","time":0734638713924754}
```

Do note that if you are building a release, you will need to manually add
the `tuplelog` dependency to your `relx` configuration, since it is
technically not a direct dependency of any application in your system.

Migration
-----

Changing a large codebase over to using the LOGT macros would require a lot of manual editing.  You
can instead use a tool like ast-grep to search and replace exiting LOG macros:
1) https://ast-grep.github.io/
2) Add Erlang support:
https://ast-grep.github.io/advanced/custom-language.html
https://github.com/WhatsApp/tree-sitter-erlang
4) Run this in your source directory: 

```bash
ast-grep scan -r $REPO_LOCATION/sripts/log_fix.yaml -U
```

5) You will need to include tuplelog.hrl anywhere you are currently including logger.hrl to get
access to the LOGT macros:

```bash
sed -i 's/\-include_lib(\"kernel\/include\/logger.hrl\")\./-include_lib\(\"kernel\/include\/logger.hrl\"\)\.\n-include_lib\(\"tuplelog/include/tuplelog.hrl\"\)\./g' *.erl

grep -c tuplelog.hrl *.erl | grep ":2"
```

Credits
-------
This project was based upon [flatlog](https://github.com/ferd/flatlog)

Roadmap
-------

- %TODO

Changelog
---------

- 0.1.0: %TODO

EXTRA
----
1) Use a macro to log a io:format string with a list of key/value tuples as data instead of a list
of variables:
    Test = "Rest",
    
    this:
    ?LOG_FORMAT("This is a test: ~s", [Test]).
    produces this:
    "This is a Rest"

    using tuplelog:
    ?LOGT_FORMAT("Thist is a test: ~s",[{test,Test}]).
    produces this:
    #{unstructured_log => "This is a Rest", template_log => "This is a $test", test => "Rest"}
    which is formatted by two different log formatters:


2) This creates a Map of key/values and adds two keys: template_log and unstructured_log.
unstructured_log is the log statememt with the value of the variables
template_log is the log statement with the name of the variables prepended with $.


1) Can do both structured and human scannable logs by converting all logs to key=>values, and then
using log formatters to format them locally for viewing and remotely for ELK consumption.
2) Use an ordered list of key values in logging statements to provide both structured and human
scannable logs.
3) Nice to log the log statement to provide a human comprehensible link between the human scannable and structured logs: template_log.
