
@testitem "Aqua" tags = [:linting] begin
    using Aqua: Aqua
    using OCPP

    Aqua.test_all(OCPP)
end

@testitem "JET" tags = [:linting] begin
    if v"1.12" <= VERSION < v"1.13"
        using JET: JET
        using OCPP

        JET.test_package(OCPP; target_modules = (OCPP,))
    end
end
