module Neighborhood_gen

export Neighborhood, get_max_nbhd_size

using ..NurseSchedules
using Random

import Base: length, iterate

function get_max_nbhd_size(schedule::Schedule)::Int
    _, shifts = get_shifts(schedule)

    from_addtition = count(s -> (s == W), shifts) * length(CHANGEABLE_SHIFTS)
    @debug "Neighbors number from addition: $from_addtition"
    from_deletion = count(s -> (s in CHANGEABLE_SHIFTS), shifts)
    @debug "Neighbors number from deletion: $from_deletion"

    from_swap = sum([
        1
        for # shift = (person_no, day_no)
        shift in CartesianIndices(shifts),
        o_shift in CartesianIndices(shifts) if
        shifts[shift] != shifts[o_shift] &&
        shift[2] == o_shift[2] &&
        shift < o_shift &&
        shifts[shift] in CHANGEABLE_SHIFTS &&
        shifts[o_shift] in CHANGEABLE_SHIFTS
    ])
    @debug "Neighbors number from swap: $from_swap"

    return from_addtition + from_deletion + from_swap
end

struct Neighborhood
    neighboring_shifts::Array{Shifts,1}

    function Neighborhood(shifts::Shifts)
        neighboring_shifts = get_nbhd(shifts)
        shuffle!(neighboring_shifts)
        new(neighboring_shifts)
    end
end

length(nbhd::Neighborhood) = length(nbhd.neighboring_shifts)

iterate(nbhd::Neighborhood) = nbhd.neighboring_shifts[1], nbhd.neighboring_shifts[2:end]

function iterate(nbhd::Neighborhood, neighboring_shifts::Array{Shifts,1})
    if isempty(neighboring_shifts)
        nothing
    else
        neighboring_shifts[1], neighboring_shifts[2:end]
    end
end

function get_nbhd(shifts::Shifts)::Array{Shifts,1}
    neighborhood = Array{String,2}[]

    for person_shift in CartesianIndices(shifts)
        mutated_schedules = if shifts[person_shift] == W
            with_shift_addtion(shifts, person_shift)
        elseif shifts[person_shift] in CHANGEABLE_SHIFTS
            vcat(
                with_shift_deletion(shifts, person_shift),
                with_shift_swap(shifts, person_shift),
            )
        else
            []
        end
        append!(neighborhood, mutated_schedules)
    end
    return neighborhood
end


function with_shift_addtion(shifts::Array{String,2}, person_shift)::Array{Array{String,2}}
    mutated_schedules = Array{String,2}[]

    for allowed_shift in CHANGEABLE_SHIFTS
        mutated_schedule = copy(shifts)
        mutated_schedule[person_shift] = allowed_shift
        push!(mutated_schedules, mutated_schedule)
    end
    return mutated_schedules
end

function with_shift_deletion(shifts::Array{String,2}, person_shift)::Array{Array{String,2}}
    mutated_schedule = copy(shifts)
    mutated_schedule[person_shift] = W
    return [mutated_schedule]
end

function with_shift_swap(shifts::Array{String,2}, shift)::Array{Array{String,2}}
    mutated_schedules = Array{String,2}[]

    for o_shift in CartesianIndices(shifts)
        if shifts[shift] != shifts[o_shift] &&
           shift[2] == o_shift[2] &&
           shift < o_shift &&
           shifts[shift] in CHANGEABLE_SHIFTS &&
           shifts[o_shift] in CHANGEABLE_SHIFTS

            mutated_schedule = copy(shifts)
            mutated_schedule[shift], mutated_schedule[o_shift] =
                mutated_schedule[o_shift], mutated_schedule[shift]

            push!(mutated_schedules, mutated_schedule)
        end
    end
    return mutated_schedules
end

end # Neighborhood
