@testitem "request_type lookup" tags = [:fast] begin
    using OCPP.V16
    @test request_type("BootNotification") == BootNotificationRequest
    @test request_type("Heartbeat") == HeartbeatRequest
    @test request_type("StartTransaction") == StartTransactionRequest
end

@testitem "response_type lookup" tags = [:fast] begin
    using OCPP.V16
    @test response_type("BootNotification") == BootNotificationResponse
    @test response_type("Heartbeat") == HeartbeatResponse
    @test response_type("StartTransaction") == StartTransactionResponse
end

@testitem "All 28 actions present in registry" tags = [:fast] begin
    using OCPP.V16
    @test length(V16_ACTIONS) == 28
    expected_actions = [
        "Authorize",
        "BootNotification",
        "CancelReservation",
        "ChangeAvailability",
        "ChangeConfiguration",
        "ClearCache",
        "ClearChargingProfile",
        "DataTransfer",
        "DiagnosticsStatusNotification",
        "FirmwareStatusNotification",
        "GetCompositeSchedule",
        "GetConfiguration",
        "GetDiagnostics",
        "GetLocalListVersion",
        "Heartbeat",
        "MeterValues",
        "RemoteStartTransaction",
        "RemoteStopTransaction",
        "ReserveNow",
        "Reset",
        "SendLocalList",
        "SetChargingProfile",
        "StartTransaction",
        "StatusNotification",
        "StopTransaction",
        "TriggerMessage",
        "UnlockConnector",
        "UpdateFirmware",
    ]
    for action in expected_actions
        @test haskey(V16_ACTIONS, action)
    end
end

@testitem "Unknown action throws ArgumentError" tags = [:fast] begin
    using OCPP.V16
    @test_throws ArgumentError request_type("FakeAction")
    @test_throws ArgumentError response_type("FakeAction")
end

@testitem "Registry types are concrete" tags = [:fast] begin
    using OCPP.V16
    for (action, types) in V16_ACTIONS
        @test isconcretetype(types.request)
        @test isconcretetype(types.response)
    end
end
