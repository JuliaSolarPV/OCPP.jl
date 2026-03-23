# Cross-validation tests: serialize Julia types to JSON, validate with Python ocpp library
# via PythonCall.jl.
#
# Run:
#   julia --project=test -e 'using TestItemRunner; @run_package_tests filter=ti->endswith(ti.filename, "test-python-crossvalidation.jl") verbose=true'

@testsnippet PythonOCPP begin
    # Must be set before `using PythonCall` so it picks the right interpreter
    ENV["JULIA_PYTHONCALL_EXE"] =
        joinpath(@__DIR__, "python", ".venv", "bin", "python")
    using PythonCall
    import JSON

    const _ocpp_messages = pyimport("ocpp.messages")
    const _pyjson = pyimport("json")
    const _PyCall = _ocpp_messages.Call
    const _PyCallResult = _ocpp_messages.CallResult
    const _validate = _ocpp_messages._validate_payload

    # Recursively remove nothing/null values so optional absent fields
    # don't appear as null in the payload (OCPP schemas disallow null).
    function _strip_nulls!(d::AbstractDict)
        for k in collect(keys(d))
            v = d[k]
            if v === nothing
                delete!(d, k)
            elseif v isa AbstractDict
                _strip_nulls!(v)
            elseif v isa Vector
                for item in v
                    item isa AbstractDict && _strip_nulls!(item)
                end
            end
        end
        return d
    end

    function _to_pydict(julia_struct)
        d = JSON.parse(JSON.json(julia_struct))
        _strip_nulls!(d)
        return _pyjson.loads(JSON.json(d))
    end

    """Validate a Julia struct as an OCPP request payload."""
    function py_validate_request(action::String, version::String, julia_struct)
        msg = _PyCall(unique_id = "1", action = action, payload = _to_pydict(julia_struct))
        _validate(msg; ocpp_version = version)
    end

    """Validate a Julia struct as an OCPP response payload."""
    function py_validate_response(action::String, version::String, julia_struct)
        msg =
            _PyCallResult(unique_id = "1", action = action, payload = _to_pydict(julia_struct))
        _validate(msg; ocpp_version = version)
    end
end

# ---------------------------------------------------------------------------
# V16
# ---------------------------------------------------------------------------

@testitem "PY: V16 BootNotificationRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V16
    using JSON
    req = BootNotificationRequest(
        charge_point_vendor = "TestVendor",
        charge_point_model = "TestModel",
        firmware_version = "1.0.0",
    )
    py_validate_request("BootNotification", "1.6", req)
    @test true
end

@testitem "PY: V16 BootNotificationResponse" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    resp = BootNotificationResponse(
        status = RegistrationAccepted,
        current_time = "2025-01-01T00:00:00Z",
        interval = 300,
    )
    py_validate_response("BootNotification", "1.6", resp)
    @test true
end

@testitem "PY: V16 HeartbeatRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    py_validate_request("Heartbeat", "1.6", HeartbeatRequest())
    @test true
end

@testitem "PY: V16 AuthorizeRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    py_validate_request("Authorize", "1.6", AuthorizeRequest(id_tag = "RFID1234"))
    @test true
end

@testitem "PY: V16 StartTransactionRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    req = StartTransactionRequest(
        connector_id = 1,
        id_tag = "RFID1234",
        meter_start = 0,
        timestamp = "2025-01-01T12:00:00Z",
    )
    py_validate_request("StartTransaction", "1.6", req)
    @test true
end

@testitem "PY: V16 StopTransactionRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    req = StopTransactionRequest(
        meter_stop = 5000,
        timestamp = "2025-01-01T13:00:00Z",
        transaction_id = 42,
    )
    py_validate_request("StopTransaction", "1.6", req)
    @test true
end

@testitem "PY: V16 StatusNotificationRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V16
    using JSON
    req = StatusNotificationRequest(
        connector_id = 1,
        error_code = NoError,
        status = ChargePointAvailable,
    )
    py_validate_request("StatusNotification", "1.6", req)
    @test true
end

@testitem "PY: V16 MeterValuesRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    req = MeterValuesRequest(
        connector_id = 1,
        meter_value = [
            MeterValue(
                timestamp = "2025-01-01T12:00:00Z",
                sampled_value = [
                    SampledValue(
                        value = "100.5",
                        measurand = MeasurandEnergyActiveImportRegister,
                        unit = UnitkWh,
                    ),
                ],
            ),
        ],
    )
    py_validate_request("MeterValues", "1.6", req)
    @test true
end

@testitem "PY: V16 SetChargingProfileRequest float limit" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V16
    using JSON
    req = SetChargingProfileRequest(
        connector_id = 1,
        cs_charging_profiles = ChargingProfile(
            charging_profile_id = 1,
            stack_level = 0,
            charging_profile_purpose = TxProfile,
            charging_profile_kind = Relative,
            charging_schedule = ChargingSchedule(
                charging_rate_unit = ChargingRateA,
                charging_schedule_period = [
                    ChargingSchedulePeriod(start_period = 0, limit = 21.4),
                ],
            ),
            transaction_id = 123456789,
        ),
    )
    py_validate_request("SetChargingProfile", "1.6", req)
    @test true
end

@testitem "PY: V16 ChangeConfigurationRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V16
    using JSON
    req = ChangeConfigurationRequest(key = "HeartbeatInterval", value = "300")
    py_validate_request("ChangeConfiguration", "1.6", req)
    @test true
end

@testitem "PY: V16 ResetRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V16
    using JSON
    py_validate_request("Reset", "1.6", ResetRequest(type = ResetHard))
    @test true
end

# ---------------------------------------------------------------------------
# V201
# ---------------------------------------------------------------------------

@testitem "PY: V201 BootNotificationRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V201
    using JSON
    req = BootNotificationRequest(
        reason = BootReasonPowerUp,
        charging_station = ChargingStation(model = "TestModel", vendor_name = "TestVendor"),
    )
    py_validate_request("BootNotification", "2.0.1", req)
    @test true
end

@testitem "PY: V201 BootNotificationResponse" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V201
    using JSON
    resp = BootNotificationResponse(
        status = RegistrationAccepted,
        current_time = "2025-01-01T00:00:00Z",
        interval = 300,
    )
    py_validate_response("BootNotification", "2.0.1", resp)
    @test true
end

@testitem "PY: V201 HeartbeatRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V201
    using JSON
    py_validate_request("Heartbeat", "2.0.1", HeartbeatRequest())
    @test true
end

@testitem "PY: V201 AuthorizeRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V201
    using JSON
    req = AuthorizeRequest(id_token = IdToken(id_token = "RFID1234", type = IdTokenCentral))
    py_validate_request("Authorize", "2.0.1", req)
    @test true
end

@testitem "PY: V201 TransactionEventRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V201
    using JSON
    req = TransactionEventRequest(
        event_type = Started,
        timestamp = "2025-01-01T12:00:00Z",
        trigger_reason = TriggerReasonAuthorized,
        seq_no = 0,
        transaction_info = Transaction(transaction_id = "tx-001"),
    )
    py_validate_request("TransactionEvent", "2.0.1", req)
    @test true
end

@testitem "PY: V201 StatusNotificationRequest" tags = [:crossvalidation] setup = [
    PythonOCPP,
] begin
    using OCPP.V201
    using JSON
    req = StatusNotificationRequest(
        timestamp = "2025-01-01T12:00:00Z",
        connector_status = ConnectorAvailable,
        evse_id = 1,
        connector_id = 1,
    )
    py_validate_request("StatusNotification", "2.0.1", req)
    @test true
end

@testitem "PY: V201 GetVariablesRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V201
    using JSON
    req = GetVariablesRequest(
        get_variable_data = [
            GetVariableData(
                component = Component(name = "SmartChargingCtrlr"),
                variable = Variable(name = "Enabled"),
            ),
        ],
    )
    py_validate_request("GetVariables", "2.0.1", req)
    @test true
end

@testitem "PY: V201 ResetRequest" tags = [:crossvalidation] setup = [PythonOCPP] begin
    using OCPP.V201
    using JSON
    py_validate_request("Reset", "2.0.1", ResetRequest(type = Immediate))
    @test true
end
