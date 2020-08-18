struct Schedule
    data::Dict

    function Schedule(filename::AbstractString)
        data = JSON.parsefile(filename)
        @printf "%s\n" "Schedule loaded!"

        validate(data)

        new(data)
    end

end

function get_shifts(schedule::Schedule)::Array{String, 2}
    shifts = collect(values(schedule.data["shifts"]))
    return [shifts[person][shift]
            for person in 1:length(shifts),
            shift in 1:length(shifts[1])]
end
