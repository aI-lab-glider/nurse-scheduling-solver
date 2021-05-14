# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

x = Dict{String, Any}(
    "from" => 12,
    "to" => 18,
    "is_working_shift" => true
)
y = Dict{String, Any}(
    "from" => 20,
    "to" => 6,
    "is_working_shift" => true
)
z = Dict{String, Any}(
    "from" => 2,
    "to" => 8,
    "is_working_shift" => true
)
a = Dict{String, Any}(
    "from" => 2,
    "to" => 8,
    "is_working_shift" => false
)


@testset "within" begin
    @test within(15, x) == true
    @test within(18, x) == false
    @test within(2, y) == true
    @test within(20, y) == true
    @test within(7, a) == false
end

@testset "get_next_day_distance" begin
    @test get_next_day_distance(x, y) == 26
    @test get_next_day_distance(x, z) == 8 
    @test get_next_day_distance(y, x) == 6
    @test get_next_day_distance(y, z) == -4
    @test get_next_day_distance(z, x) == 28
    @test get_next_day_distance(z, y) == 36
end

@testset "sum_segments" begin
    segments = [
        (1, 3),
        (6, 8)
    ]
    @test sum_segments(segments) == 4
    push!(segments, (22, 2))
    @test sum_segments(segments) == 8
end