@testitem "Call convenience constructor" tags = [:fast] begin
    using OCPP
    msg = Call("abc-123", "BootNotification", Dict{String,Any}("key" => "val"))
    @test msg.message_type_id == 2
    @test msg.unique_id == "abc-123"
    @test msg.action == "BootNotification"
    @test msg.payload == Dict{String,Any}("key" => "val")
end

@testitem "CallResult convenience constructor" tags = [:fast] begin
    using OCPP
    msg = CallResult("abc-123", Dict{String,Any}("status" => "Accepted"))
    @test msg.message_type_id == 3
    @test msg.unique_id == "abc-123"
    @test msg.payload == Dict{String,Any}("status" => "Accepted")
end

@testitem "CallError convenience constructor" tags = [:fast] begin
    using OCPP
    msg = CallError("abc-123", "NotImplemented", "No handler", Dict{String,Any}())
    @test msg.message_type_id == 4
    @test msg.unique_id == "abc-123"
    @test msg.error_code == "NotImplemented"
    @test msg.error_description == "No handler"
    @test msg.error_details == Dict{String,Any}()
end

@testitem "Full constructor preserves message_type_id" tags = [:fast] begin
    using OCPP
    msg = Call(2, "id", "Action", Dict{String,Any}())
    @test msg.message_type_id == 2
end
