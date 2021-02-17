module Logger

include("logConstants.jl")

export get_new_log_id

using Logging
# Log setup
if SAVE_STD
    io = open(STD_LOG, "w+")
    logger = SimpleLogger(io)
    global_logger(logger)
end

function get_new_log_id(log_dir::String)::Int
    files = readdir(log_dir)
    if empty(files)
        1
    else
        max(
            map(
                x -> parse(Int, x),
                filter(
                    isinteger,
                    map(
                        x -> split(x, '.')[1],
                        files
        )))) + 1
    end
end

function save_schedule(schedule::Dict, id::Int)
    if SAVE_SCHEDULES
        open(REQUEST_DIR * string(log_id) * ".txt", "w") do 
            JSON.print(f, schedule_data)
        end
    end
end

end # Logger