-define(LOGT_INFO(Format, Terms),
    ?LOG_INFO(tuplelog:proplist_log_to_map(Format, Terms))
).
-define(LOGT_ERROR(Format, Terms),
    ?LOG_ERROR(tuplelog:proplist_log_to_map(Format, Terms))
).
-define(LOGT_DEBUG(Format, Terms),
    ?LOG_DEBUG(tuplelog:proplist_log_to_map(Format, Terms))
).

-define(IO_FORMATP(Format, Terms),
    tuplelog:proplist_format(Format, Terms)
).

-define(IO_LIB_FORMATP(Format, Terms),
    tuplelog:proplist_lib_format(Format, Terms)
).

-include_lib("kernel/include/logger.hrl").
