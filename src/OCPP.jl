module OCPP

using JSON3
using StructTypes
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
using StructTypes
using JSON3
using ..OCPP: generate_types!

include("v16/registries.jl")

const _SCHEMA_DIR =
    joinpath(@__DIR__, "..", "ocpp-files", "OCPP_1.6_documentation", "schemas", "json")
generate_types!(
    @__MODULE__,
    _SCHEMA_DIR,
    V16_ENUM_REGISTRY,
    V16_NESTED_TYPE_NAMES,
    :V16_ACTIONS,
)
end # module V16

# Exports — protocol-level
export OCPPMessage, Call, CallResult, CallError
export encode, decode, generate_unique_id

# Re-export V16 submodule
export V16

# Precompile common operations to reduce TTFX
@compile_workload begin
    # Codec round-trip
    msg = Call("test-id", "Heartbeat", Dict{String,Any}())
    raw = encode(msg)
    decode(raw)

    # V16 type construction and JSON round-trip
    req = V16.HeartbeatRequest()
    JSON3.write(req)

    boot = V16.BootNotificationRequest(
        charge_point_vendor = "TestVendor",
        charge_point_model = "TestModel",
    )
    json_str = JSON3.write(boot)
    JSON3.read(json_str, V16.BootNotificationRequest)

    # Action registry
    V16.request_type("Heartbeat")
    V16.response_type("Heartbeat")
end

end # module OCPP
