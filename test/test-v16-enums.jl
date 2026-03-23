@testitem "Enum string() produces OCPP value" tags = [:fast] begin
    using OCPP.V16
    @test string(RegistrationAccepted) == "Accepted"
    @test string(RegistrationPending) == "Pending"
    @test string(RegistrationRejected) == "Rejected"
    @test string(NoError) == "NoError"
    @test string(ResetHard) == "Hard"
    @test string(ResetSoft) == "Soft"
    @test string(MeasurandEnergyActiveImportRegister) == "Energy.Active.Import.Register"
    @test string(PhaseL1N) == "L1-N"
    @test string(ReadingInterruptionBegin) == "Interruption.Begin"
end

@testitem "Enum JSON3 write" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    @test JSON3.write(RegistrationAccepted) == "\"Accepted\""
    @test JSON3.write(ResetHard) == "\"Hard\""
    @test JSON3.write(ChargingRateA) == "\"A\""
    @test JSON3.write(MeasurandEnergyActiveImportRegister) ==
          "\"Energy.Active.Import.Register\""
end

@testitem "Enum JSON3 read" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    @test JSON3.read("\"Accepted\"", RegistrationStatus) == RegistrationAccepted
    @test JSON3.read("\"Pending\"", RegistrationStatus) == RegistrationPending
    @test JSON3.read("\"Hard\"", ResetType) == ResetHard
    @test JSON3.read("\"A\"", ChargingRateUnitType) == ChargingRateA
end

@testitem "Enum round-trip for all RegistrationStatus values" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    for val in instances(RegistrationStatus)
        @test JSON3.read(JSON3.write(val), RegistrationStatus) == val
    end
end

@testitem "Enum round-trip for ChargePointErrorCode" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    for val in instances(ChargePointErrorCode)
        @test JSON3.read(JSON3.write(val), ChargePointErrorCode) == val
    end
end

@testitem "Enum round-trip for Measurand" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    for val in instances(Measurand)
        @test JSON3.read(JSON3.write(val), Measurand) == val
    end
end

@testitem "Enum round-trip for Phase" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    for val in instances(Phase)
        @test JSON3.read(JSON3.write(val), Phase) == val
    end
end

@testitem "Enum invalid string throws" tags = [:fast] begin
    using OCPP.V16
    using JSON3
    @test_throws KeyError JSON3.read("\"InvalidValue\"", RegistrationStatus)
end
