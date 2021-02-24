# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module Logger

include("logConstants.jl")

export get_request_name, save_schedule, flush_logs

using Dates
using Logging
using LoggingExtras
using JSON

!isdir(LOG_DIR) && mkdir(LOG_DIR)
!isdir(REQUEST_DIR) && mkdir(REQUEST_DIR)

function get_request_name()::String
    replace(REQUEST_FILE, "*" => Dates.format(Dates.now(), REQUEST_DATE_FORMAT))
end

function save_schedule(schedule_data::Dict, id::String)
    if SAVE_SCHEDULES_TO_FILE
        filename = joinpath(REQUEST_DIR, id)
        open(filename, "w") do f 
            JSON.print(f, schedule_data)
        end
    end
end

function flush_logs()
    for logger in loggers
        flush(logger.stream)
    end
end

# Log setup
loggers = []

if SAVE_TO_STDOUT
    logger = ConsoleLogger(stdout)
    push!(loggers, logger)
end

if SAVE_TO_FILE
    log_file = joinpath(LOG_DIR, LOG_FILE)
    log_file = replace(log_file, "*" => Dates.format(Dates.now(), LOG_DATE_FORMAT))
    io = open(log_file, "w")
    logger = SimpleLogger(io)
    push!(loggers, logger)
end

tee_log = TeeLogger(Tuple(loggers))
global_logger(tee_log)

end # Logger
