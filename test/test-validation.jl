@testitem "V16 valid BootNotification request" tags = [:fast] begin
    using OCPP
    result = validate(
        :v16,
        "BootNotification",
        Dict("chargePointVendor" => "TestVendor", "chargePointModel" => "TestModel"),
        :request,
    )
    @test isnothing(result)
end

@testitem "V16 missing required field" tags = [:fast] begin
    using OCPP
    result = validate(
        :v16,
        "BootNotification",
        Dict("chargePointVendor" => "TestVendor"),
        :request,
    )
    @test !isnothing(result)
    @test occursin("required", result)
end

@testitem "V16 wrong field type" tags = [:fast] begin
    using OCPP
    result = validate(
        :v16,
        "BootNotification",
        Dict("chargePointVendor" => 123, "chargePointModel" => "M"),
        :request,
    )
    @test !isnothing(result)
    @test occursin("type", result)
end

@testitem "V16 HeartbeatRequest empty payload valid" tags = [:fast] begin
    using OCPP
    result = validate(:v16, "Heartbeat", Dict{String,Any}(), :request)
    @test isnothing(result)
end

@testitem "V16 response validation" tags = [:fast] begin
    using OCPP
    result = validate(
        :v16,
        "BootNotification",
        Dict(
            "status" => "Accepted",
            "currentTime" => "2025-01-01T00:00:00Z",
            "interval" => 300,
        ),
        :response,
    )
    @test isnothing(result)
end

@testitem "V201 valid BootNotification request" tags = [:fast] begin
    using OCPP
    result = validate(
        :v201,
        "BootNotification",
        Dict(
            "reason" => "PowerUp",
            "chargingStation" => Dict("model" => "M", "vendorName" => "V"),
        ),
        :request,
    )
    @test isnothing(result)
end

@testitem "V201 missing required field" tags = [:fast] begin
    using OCPP
    result = validate(:v201, "BootNotification", Dict("reason" => "PowerUp"), :request)
    @test !isnothing(result)
    @test occursin("required", result)
end

@testitem "V201 response validation" tags = [:fast] begin
    using OCPP
    result = validate(
        :v201,
        "BootNotification",
        Dict(
            "status" => "Accepted",
            "currentTime" => "2025-01-01T00:00:00Z",
            "interval" => 300,
        ),
        :response,
    )
    @test isnothing(result)
end

@testitem "Unknown action throws ArgumentError" tags = [:fast] begin
    using OCPP
    @test_throws ArgumentError validate(
        :v16,
        "NonExistentAction",
        Dict{String,Any}(),
        :request,
    )
end

@testitem "Unknown version throws ArgumentError" tags = [:fast] begin
    using OCPP
    @test_throws ArgumentError validate(
        :v99,
        "BootNotification",
        Dict{String,Any}(),
        :request,
    )
end
