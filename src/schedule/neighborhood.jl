module NeighborsGeneration

export get_neighborhood

include("constants.jl")

using ..NurseSchedules: Schedule, get_shifts

CHANGEABLE_SHIFTS = [R, P, D, N, DN]

function get_neighborhood(schedule::Schedule)
    neighborhood = Array{String, 2}[]
    shifts = get_shifts(schedule)

    for day in eachindex(shifts)
        mutated_schedules = if shifts[day] == W
            with_shift_addtion(shifts, day)
        else
            vcat(with_shift_deletion(shifts, day), with_shift_swap(shifts, day))
        end
        append!(neighborhood, mutated_schedules)
    end

    return neighborhood
end


function with_shift_addtion(shifts::Array{String, 2}, day)::Array{Array{String, 2}}
    mutated_schedules = Array{String, 2}[]

    for allowed_shift in CHANGEABLE_SHIFTS
        mutated_schedule = copy(shifts)
        mutated_schedule[day] = allowed_shift
        push!(mutated_schedules, mutated_schedule)
    end
    return mutated_schedules
end

function with_shift_deletion(shifts::Array{String, 2}, day)::Array{Array{String, 2}}
    mutated_schedule = copy(shifts)
    mutated_schedule[day] = W
    return [mutated_schedule]
end

# exclude duplicats
function with_shift_swap(shifts::Array{String, 2}, day)::Array{Array{String, 2}}
    mutated_schedules = Array{String, 2}[]

    for shift_no in eachindex(shifts)
        if shifts[shift_no] in CHANGEABLE_SHIFTS && shift_no != day
            new_schedule = copy(shifts)
            new_schedule[day], new_schedule[shift_no] = new_schedule[shift_no], new_schedule[day]
            push!(mutated_schedules, new_schedule)
        end
    end
    return mutated_schedules
end

end # NeighborsGeneration
