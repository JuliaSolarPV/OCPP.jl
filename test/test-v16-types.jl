@testitem "BootNotificationRequest kwdef construction" tags = [:fast] begin
    using OCPP.V16
    req = BootNotificationRequest(
        charge_point_vendor = "TestVendor",
        charge_point_model = "TestModel",
    )
    @test req.charge_point_vendor == "TestVendor"
    @test req.charge_point_model == "TestModel"
    @test req.firmware_version === nothing
end

@testitem "BootNotificationRequest JSON camelCase output" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = BootNotificationRequest(
        charge_point_vendor = "Vendor",
        charge_point_model = "Model",
    )
    json = JSON3.write(req)
    @test occursin("chargePointVendor", json)
    @test occursin("chargePointModel", json)
    @test !occursin("charge_point_vendor", json)
end

@testitem "BootNotificationRequest JSON round-trip" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = BootNotificationRequest(
        charge_point_vendor = "Vendor",
        charge_point_model = "Model",
        firmware_version = "1.0",
    )
    json = JSON3.write(req)
    req2 = JSON3.read(json, BootNotificationRequest)
    @test req == req2
end

@testitem "BootNotificationResponse with enum" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    resp = BootNotificationResponse(
        status = RegistrationAccepted,
        current_time = "2025-01-01T00:00:00Z",
        interval = 300,
    )
    json = JSON3.write(resp)
    @test occursin("\"Accepted\"", json)
    @test occursin("currentTime", json)
    resp2 = JSON3.read(json, BootNotificationResponse)
    @test resp2.status == RegistrationAccepted
    @test resp2.interval == 300
end

@testitem "Empty struct round-trip" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = HeartbeatRequest()
    json = JSON3.write(req)
    @test json == "{}"
    req2 = JSON3.read(json, HeartbeatRequest)
    @test req2 isa HeartbeatRequest
end

@testitem "IdTagInfo shared sub-type" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    info = IdTagInfo(status = AuthorizationAccepted, expiry_date = "2025-12-31T23:59:59Z")
    json = JSON3.write(info)
    @test occursin("expiryDate", json)
    @test occursin("\"Accepted\"", json)
    info2 = JSON3.read(json, IdTagInfo)
    @test info2.status == AuthorizationAccepted
    @test info2.expiry_date == "2025-12-31T23:59:59Z"
end

@testitem "StartTransactionResponse with nested IdTagInfo" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    resp = StartTransactionResponse(
        transaction_id = 42,
        id_tag_info = IdTagInfo(status = AuthorizationAccepted),
    )
    json = JSON3.write(resp)
    resp2 = JSON3.read(json, StartTransactionResponse)
    @test resp2.transaction_id == 42
    @test resp2.id_tag_info.status == AuthorizationAccepted
end

@testitem "MeterValue with SampledValue" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    sv = SampledValue(
        value = "100.5",
        measurand = MeasurandEnergyActiveImportRegister,
        unit = UnitkWh,
    )
    mv = MeterValue(timestamp = "2025-01-01T12:00:00Z", sampled_value = [sv])
    json = JSON3.write(mv)
    @test occursin("sampledValue", json)
    @test occursin("Energy.Active.Import.Register", json)
    mv2 = JSON3.read(json, MeterValue)
    @test mv2.sampled_value[1].value == "100.5"
    @test mv2.sampled_value[1].measurand == MeasurandEnergyActiveImportRegister
end

@testitem "ChargingProfile nested struct" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    profile = ChargingProfile(
        charging_profile_id = 1,
        stack_level = 0,
        charging_profile_purpose = TxDefaultProfile,
        charging_profile_kind = Absolute,
        charging_schedule = ChargingSchedule(
            charging_rate_unit = ChargingRateW,
            charging_schedule_period = [
                ChargingSchedulePeriod(start_period = 0, limit = 11000.0),
                ChargingSchedulePeriod(start_period = 3600, limit = 7400.0),
            ],
        ),
    )
    json = JSON3.write(profile)
    @test occursin("chargingProfileId", json)
    @test occursin("chargingSchedulePeriod", json)
    profile2 = JSON3.read(json, ChargingProfile)
    @test profile2.charging_profile_id == 1
    @test length(profile2.charging_schedule.charging_schedule_period) == 2
    @test profile2.charging_schedule.charging_schedule_period[2].limit == 7400.0
end

@testitem "StopTransactionRequest with optional transaction_data" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = StopTransactionRequest(
        meter_stop = 5000,
        timestamp = "2025-01-01T13:00:00Z",
        transaction_id = 42,
        reason = ReasonLocal,
        transaction_data = [
            MeterValue(
                timestamp = "2025-01-01T13:00:00Z",
                sampled_value = [SampledValue(value = "5000")],
            ),
        ],
    )
    json = JSON3.write(req)
    req2 = JSON3.read(json, StopTransactionRequest)
    @test req2.reason == ReasonLocal
    @test req2.transaction_data[1].sampled_value[1].value == "5000"
end

@testitem "StatusNotificationRequest" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = StatusNotificationRequest(
        connector_id = 1,
        error_code = NoError,
        status = ChargePointAvailable,
    )
    json = JSON3.write(req)
    @test occursin("\"NoError\"", json)
    @test occursin("\"Available\"", json)
    req2 = JSON3.read(json, StatusNotificationRequest)
    @test req2.error_code == NoError
    @test req2.status == ChargePointAvailable
end

@testitem "SetChargingProfileRequest camelCase for csChargingProfiles" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    req = SetChargingProfileRequest(
        connector_id = 1,
        cs_charging_profiles = ChargingProfile(
            charging_profile_id = 1,
            stack_level = 0,
            charging_profile_purpose = ChargePointMaxProfile,
            charging_profile_kind = Absolute,
            charging_schedule = ChargingSchedule(
                charging_rate_unit = ChargingRateA,
                charging_schedule_period = [
                    ChargingSchedulePeriod(start_period = 0, limit = 32.0),
                ],
            ),
        ),
    )
    json = JSON3.write(req)
    @test occursin("csChargingProfiles", json)
    req2 = JSON3.read(json, SetChargingProfileRequest)
    @test req2.cs_charging_profiles.charging_profile_id == 1
end
