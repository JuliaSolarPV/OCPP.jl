module OCPPData

using JSON
using StructUtils
using UUIDs
using PrecompileTools

# Protocol-level message types (version-independent)
include("messages.jl")

# Codec: encode/decode OCPP-J wire format
include("codec.jl")

# Version-agnostic schema reader
include("schema_reader.jl")

# OCPP 1.6 submodule
module V16
using StructUtils
using JSON
import JSONSchema
using ..OCPPData: @generate_ocpp_types, AbstractOCPPSpec

struct Spec <: AbstractOCPPSpec end
export Spec

include("v16/registries.jl")

const _SCHEMA_DIR = joinpath(@__DIR__, "v16", "schemas")
@generate_ocpp_types _SCHEMA_DIR V16_ENUM_REGISTRY V16_NESTED_TYPE_NAMES :V16_ACTIONS

const _SCHEMAS = Dict{String,JSONSchema.Schema}()
end # module V16

# OCPP 2.0.1 submodule
module V201
using StructUtils
using JSON
import JSONSchema
using ..OCPPData: @generate_ocpp_types_from_definitions, AbstractOCPPSpec

struct Spec <: AbstractOCPPSpec end
export Spec

const _SCHEMA_DIR = joinpath(@__DIR__, "v201", "schemas")
@generate_ocpp_types_from_definitions _SCHEMA_DIR :V201_ACTIONS

const _SCHEMAS = Dict{String,JSONSchema.Schema}()
end # module V201

# Schema validation
include("validation.jl")

# Eagerly load all schemas at module init time
_load_all_schemas!(
    V16._SCHEMAS,
    V16._SCHEMA_DIR,
    V16.V16_ACTIONS,
    (a, mt) -> mt == :request ? "$(a).json" : "$(a)Response.json",
)
_load_all_schemas!(
    V201._SCHEMAS,
    V201._SCHEMA_DIR,
    V201.V201_ACTIONS,
    (a, mt) -> mt == :request ? "$(a)Request.json" : "$(a)Response.json",
)

# Exports — protocol-level
export OCPPMessage, Call, CallResult, CallError
export AbstractOCPPSpec
export encode, decode, generate_unique_id, validate

# Re-export version submodules
export V16, V201

# Precompile common operations to reduce TTFX
@compile_workload begin
    # Codec round-trip
    msg = Call("test-id", "Heartbeat", Dict{String,Any}())
    raw = encode(msg)
    decode(raw)

    # V16 type construction and JSON round-trip
    req = V16.HeartbeatRequest()
    JSON.json(req)

    boot = V16.BootNotificationRequest(
        charge_point_vendor = "TestVendor",
        charge_point_model = "TestModel",
    )
    json_str = JSON.json(boot)
    JSON.parse(json_str, V16.BootNotificationRequest)

    # Action registry
    V16.request_type("Heartbeat")
    V16.response_type("Heartbeat")

    # Schema validation — all four dispatch paths (V16/V201 × request/response)
    validate(
        V16.Spec(),
        "BootNotification",
        Dict{String,Any}("chargePointVendor" => "V", "chargePointModel" => "M"),
        :request,
    )
    validate(
        V16.Spec(),
        "BootNotification",
        Dict{String,Any}(
            "status" => "Accepted",
            "currentTime" => "2025-01-01T00:00:00Z",
            "interval" => 300,
        ),
        :response,
    )
    validate(
        V201.Spec(),
        "BootNotification",
        Dict{String,Any}(
            "reason" => "PowerUp",
            "chargingStation" => Dict{String,Any}("vendorName" => "V", "model" => "M"),
        ),
        :request,
    )
    validate(
        V201.Spec(),
        "BootNotification",
        Dict{String,Any}(
            "status" => "Accepted",
            "currentTime" => "2025-01-01T00:00:00.000Z",
            "interval" => 300,
        ),
        :response,
    )
end

end # module OCPPData
