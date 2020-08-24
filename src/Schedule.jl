struct Schedule
    data::Dict

    function Schedule(filename::AbstractString)
        data = JSON.parsefile(filename)
        @info "Schedule loaded!"

        validate(data)

        new(data)
    end

end

function get_shifts(schedule::Schedule)::Array{String,2}
    shifts = collect(values(schedule.data["shifts"]))
    return [
        shifts[person][shift] for person = 1:length(shifts), shift = 1:length(shifts[1])
    ]
end
