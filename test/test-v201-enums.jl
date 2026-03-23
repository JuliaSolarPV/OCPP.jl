@testitem "V201 enum string() produces OCPP value" tags = [:fast] begin
    using OCPP.V201
    @test string(BootReasonPowerUp) == "PowerUp"
    @test string(BootReasonWatchdog) == "Watchdog"
    @test string(RegistrationAccepted) == "Accepted"
    @test string(RegistrationPending) == "Pending"
    @test string(GenericAccepted) == "Accepted"
    @test string(GenericRejected) == "Rejected"
    @test string(Immediate) == "Immediate"
    @test string(OnIdle) == "OnIdle"
end

@testitem "V201 enum JSON3 write" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    @test JSON3.write(BootReasonPowerUp) == "\"PowerUp\""
    @test JSON3.write(RegistrationAccepted) == "\"Accepted\""
    @test JSON3.write(A) == "\"A\""
end

@testitem "V201 enum JSON3 read" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    @test JSON3.read("\"PowerUp\"", BootReason) == BootReasonPowerUp
    @test JSON3.read("\"Accepted\"", RegistrationStatus) == RegistrationAccepted
    @test JSON3.read("\"Immediate\"", Reset) == Immediate
end

@testitem "V201 enum round-trip for BootReason" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    for val in instances(BootReason)
        @test JSON3.read(JSON3.write(val), BootReason) == val
    end
end

@testitem "V201 enum round-trip for ConnectorStatus" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    for val in instances(ConnectorStatus)
        @test JSON3.read(JSON3.write(val), ConnectorStatus) == val
    end
end

@testitem "V201 enum round-trip for Measurand" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    for val in instances(Measurand)
        @test JSON3.read(JSON3.write(val), Measurand) == val
    end
end

@testitem "V201 enum invalid string throws" tags = [:fast] begin
    using OCPP.V201
    using JSON3
    @test_throws KeyError JSON3.read("\"InvalidValue\"", RegistrationStatus)
end
