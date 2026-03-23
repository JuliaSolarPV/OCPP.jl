using OCPP
using Documenter

DocMeta.setdocmeta!(OCPP, :DocTestSetup, :(using OCPP); recursive = true)

const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
    file != "index.md" && splitext(file)[2] == ".md"
]

makedocs(;
    modules = [OCPP],
    authors = "Stefan de Lange <langestefan@msn.com>",
    repo = "https://github.com/JuliaSolarPV/OCPP.jl/blob/{commit}{path}#{line}",
    sitename = "OCPP.jl",
    format = Documenter.HTML(; canonical = "https://JuliaSolarPV.github.io/OCPP.jl"),
    pages = ["index.md"; numbered_pages],
)

deploydocs(; repo = "github.com/JuliaSolarPV/OCPP.jl")
