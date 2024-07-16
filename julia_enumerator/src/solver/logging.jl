
using Logging
using Distributed

function log_fmt(level::LogLevel, _module, group, id, file, line)
    color, prefix, suffix = Logging.default_metafmt(level, _module, group, id, file, line)
    prefix = "Pid: $(myid()) " * prefix
    color, prefix, suffix
end

function init_logger()
    Base.global_logger(Logging.ConsoleLogger(stderr, meta_formatter=log_fmt))
end
