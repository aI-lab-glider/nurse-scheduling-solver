# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module Logger

include("logConstants.jl")

export get_new_log_id, save_schedule

using Dates
using Logging
using LoggingExtras
using JSON

function get_new_log_id()::Int
    files = readdir(REQUEST_DIR)
    filenames = map(x -> split(x, '.')[1], files)
    numeric_files = filter(x -> occursin(r"[0-9]+", x), filenames)
    log_ids = map(x -> parse(Int, x), numeric_files)
    if isempty(log_ids)
        1
    else
        maximum(log_ids) + 1
    end
end

function save_schedule(schedule_data::Dict, id::Int)
    if SAVE_SCHEDULES_TO_FILE
        filename = REQUEST_DIR * "/" * string(id) * ".txt"
        open(filename, "w") do f 
            JSON.print(f, schedule_data)
        end
    end
end

# Log setup
loggers = []
if SAVE_TO_STDOUT
    logger = ConsoleLogger(stdout)
    push!(loggers, logger)
end

if SAVE_TO_FILE
    log_file = replace(LOG_FILE, "*" => Dates.format(Dates.now(), DATE_FORMAT))
    io = open(log_file, "w")
    logger = SimpleLogger(io)
    push!(loggers, logger)
end

tee_log = TeeLogger(Tuple(loggers))
global_logger(tee_log)

end # Logger