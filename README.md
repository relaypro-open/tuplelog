tuplelog
=====

A macro collection and optional log formatter for the logger application that allows the use of tuples in log statements to provide both human readable and structured logging in one statement.  Works along with other log formatters (like flatlog, logger_formatter_json) to provide structured logging.

Why?
----

Structured logging has huge advantages over human readable logs, mainly so log analysis tools like
ElasticSearch can be used, but there are disadvantages also.
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

- Structured logs, which are not stored locally, but are streamed to a log storage and analysis systems (like ELK)
- Human readable logs that only exist locally, allowing local tailing


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


The logging output will then be supported. Calling the logger like:

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

If sent to the tuplelog log formatter, this will produce a standard formatted log entry like:
```erlang
1970-12-12T00:01:20.286786+00:00 [info] <0.PID.0> module:function/arrity:line_number Result: Test
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
3) Create the following ast-grep rule in a file:
log_fix.yaml
```yaml
---

id: log_rewrite
language: erlang
# find the target node
rule:
  all:
    - kind: macro_call_expr
    - pattern: "?$MACRO($FORMAT,$$$TERMS)"
    - not:
        has:
          kind: call    # a sub rule object
          stopBy: end                  # stopBy accepts 'end', 'neighbor' or another rule object.
# apply rewriters to sub node
transform:
  MACRO_NEW:
    replace:
      source: $MACRO
      replace: "LOG_(?<LEVEL>.*)" 
      by: LOGP_$LEVEL
  TUPLES:
    rewrite:
      rewriters: [tuple-rewrite]
      source: $$$TERMS
# combine and replace
fix: ?$MACRO_NEW($FORMAT, $TUPLES)

# define rewriters
rewriters:
- id: tuple-rewrite
  rule:
    pattern: $VARNAME
    kind: var
  transform:
    KEY:
      convert:
        source: $VARNAME
        toCase: snakeCase
  fix: "{$KEY,$VARNAME}"

```

4) Run this in your source directory: 

```bash
ast-grep scan -r log_fix.yaml -U
```

5) You will need to include tuplelog.hrl anywhere you are currently including logger.hrl to get
access to the LOGT macros:

```bash
sed -i 's/\-include_lib(\"kernel\/include\/logger.hrl\")\./-include_lib\(\"kernel\/include\/logger.hrl\"\)\.\n-include_lib\(\"tuplelog/include/tuplelog.hrl\"\)\./g' *.erl

grep -c dog_trainer.hrl *.erl | grep ":2"
```

Roadmap
-------

- %TODO

Changelog
---------

- 0.1.0: %TODO
