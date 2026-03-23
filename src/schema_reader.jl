"""
Read OCPP JSON schema files and generate Julia types at module load time.

Version-agnostic logic for:
- Reading JSON schema files
- Extracting enum value sets and generating @enum types
- Extracting struct field definitions and generating @kwdef structs
- Building action registries

Each OCPP version provides its own `enum_registry` and `nested_type_names`
mappings, then calls `generate_types!` with those registries.
"""

# ---------------------------------------------------------------------------
# Schema reading
# ---------------------------------------------------------------------------

"""
    read_schemas(schema_dir::String) -> Dict{String, Any}

Read all JSON schema files from a directory. Returns a Dict mapping
schema title (e.g. "BootNotificationRequest") to parsed schema.
"""
function read_schemas(schema_dir::String)
    schemas = Dict{String,Any}()
    for fname in readdir(schema_dir)
        endswith(fname, ".json") || continue
        path = joinpath(schema_dir, fname)
        schema = JSON3.read(read(path, String), Dict{String,Any})
        title = get(schema, "title", replace(fname, ".json" => ""))
        schemas[title] = schema
    end
    return schemas
end

# ---------------------------------------------------------------------------
# Enum helpers
# ---------------------------------------------------------------------------

"""Convert an OCPP enum string value to a valid Julia identifier."""
function _ocpp_string_to_identifier(s::String)
    return replace(s, "." => "", "-" => "")
end

"""Create a Julia enum member name from a prefix and OCPP string value."""
function _make_member_name(prefix::String, value::String)
    clean = _ocpp_string_to_identifier(value)
    if isempty(prefix)
        return Symbol(clean)
    end
    # Don't double-prefix if value already starts with prefix-like text
    if startswith(clean, prefix)
        return Symbol(clean)
    end
    return Symbol(prefix, clean)
end

"""
    collect_enums(schemas, enum_registry) -> Dict{Symbol, Vector{Pair{Symbol,String}}}

Scan all schemas, extract unique enum value sets, look up names in
the registry, and return a Dict mapping enum type name →
[(member_name => "OCPPString"), ...].
"""
function collect_enums(schemas, enum_registry::Dict{Vector{String},Tuple{Symbol,String}})
    seen = Set{Vector{String}}()
    result = Dict{Symbol,Vector{Pair{Symbol,String}}}()

    function _walk_enum_props(props)
        for (_, prop) in props
            prop isa Dict || continue
            if haskey(prop, "enum")
                values = sort(String[string(v) for v in prop["enum"]])
                if values ∉ seen
                    push!(seen, values)
                    if haskey(enum_registry, values)
                        enum_name, prefix = enum_registry[values]
                        members = Pair{Symbol,String}[]
                        for v in prop["enum"]
                            sv = string(v)
                            member = _make_member_name(prefix, sv)
                            push!(members, member => sv)
                        end
                        result[enum_name] = members
                    end
                end
            end
            if get(prop, "type", nothing) == "object" && haskey(prop, "properties")
                _walk_enum_props(prop["properties"])
            end
            if get(prop, "type", nothing) == "array" && haskey(prop, "items")
                items = prop["items"]
                if items isa Dict && get(items, "type", nothing) == "object"
                    if haskey(items, "properties")
                        _walk_enum_props(items["properties"])
                    end
                end
            end
        end
    end

    for (_, schema) in schemas
        if haskey(schema, "properties")
            _walk_enum_props(schema["properties"])
        end
    end
    return result
end

# ---------------------------------------------------------------------------
# Struct field helpers
# ---------------------------------------------------------------------------

"""Map a JSON schema property to a Julia type expression."""
function _json_type_to_julia(
    prop::Dict{String,Any},
    field_name::String,
    enum_lookup::Dict{Vector{String},Symbol},
    nested_type_names::Dict{String,Symbol},
)
    if haskey(prop, "enum")
        values = sort(String[string(v) for v in prop["enum"]])
        if haskey(enum_lookup, values)
            return enum_lookup[values]
        end
        return :String
    end

    jtype = get(prop, "type", "string")
    if jtype == "string"
        return :String
    elseif jtype == "integer"
        return :Int
    elseif jtype == "number"
        return :Float64
    elseif jtype == "boolean"
        return :Bool
    elseif jtype == "object"
        if haskey(nested_type_names, field_name)
            return nested_type_names[field_name]
        end
        return :(Dict{String,Any})
    elseif jtype == "array"
        items = get(prop, "items", Dict{String,Any}())
        if items isa Dict
            item_type = get(items, "type", "string")
            if item_type == "object"
                if haskey(nested_type_names, field_name)
                    inner = nested_type_names[field_name]
                    return :(Vector{$inner})
                end
                return :(Vector{Dict{String,Any}})
            elseif item_type == "string"
                return :(Vector{String})
            elseif item_type == "integer"
                return :(Vector{Int})
            end
        end
        return :(Vector{Any})
    end
    return :Any
end

"""Convert camelCase to snake_case."""
function _camel_to_snake(s::String)::String
    result = replace(s, r"([a-z0-9])([A-Z])" => s"\1_\2")
    return lowercase(result)
end

"""Extract field definitions from a JSON schema."""
function struct_fields_from_schema(
    schema::Dict{String,Any},
    enum_lookup::Dict{Vector{String},Symbol},
    nested_type_names::Dict{String,Symbol},
)
    props = get(schema, "properties", Dict{String,Any}())
    required_set = Set{String}(get(schema, "required", String[]))

    fields =
        NamedTuple{(:json_name, :jl_name, :type, :required),Tuple{String,Symbol,Any,Bool}}[]

    for (json_name, prop) in props
        prop isa Dict || continue
        jl_name = Symbol(_camel_to_snake(json_name))
        jl_type = _json_type_to_julia(prop, json_name, enum_lookup, nested_type_names)
        is_required = json_name in required_set
        push!(
            fields,
            (
                json_name = json_name,
                jl_name = jl_name,
                type = jl_type,
                required = is_required,
            ),
        )
    end

    # Sort: required fields first, then optional, alphabetical within each
    sort!(fields; by = f -> (!f.required, f.json_name))
    return fields
end

"""
Collect all nested object types that need to be generated as shared
sub-types. Returns them in dependency order (leaves first).
"""
function collect_nested_types(
    schemas,
    enum_lookup::Dict{Vector{String},Symbol},
    nested_type_names::Dict{String,Symbol},
)
    nested = Dict{Symbol,Any}()

    function _walk_nested_props(props)
        for (name, prop) in props
            prop isa Dict || continue
            ptype = get(prop, "type", nothing)

            if ptype == "object" && haskey(prop, "properties")
                if haskey(nested_type_names, name)
                    tname = nested_type_names[name]
                    if !haskey(nested, tname)
                        nested[tname] = prop
                        _walk_nested_props(prop["properties"])
                    end
                end
            elseif ptype == "array" && haskey(prop, "items")
                items = prop["items"]
                if items isa Dict &&
                   get(items, "type", nothing) == "object" &&
                   haskey(items, "properties")
                    if haskey(nested_type_names, name)
                        tname = nested_type_names[name]
                        if !haskey(nested, tname)
                            nested[tname] = items
                            _walk_nested_props(items["properties"])
                        end
                    end
                end
            end
        end
    end

    for (_, schema) in schemas
        if haskey(schema, "properties")
            _walk_nested_props(schema["properties"])
        end
    end

    # Build field definitions for each nested type
    type_fields = Dict{Symbol,Any}()
    for (tname, schema_dict) in nested
        type_fields[tname] =
            struct_fields_from_schema(schema_dict, enum_lookup, nested_type_names)
    end

    # Topological sort: types that depend on other nested types come after
    ordered = Pair{Symbol,Any}[]
    remaining = copy(type_fields)
    placed = Set{Symbol}()

    while !isempty(remaining)
        progress = false
        for (tname, fields) in remaining
            deps = Set{Symbol}()
            for f in fields
                ft = f.type
                if ft isa Symbol && ft in keys(type_fields)
                    push!(deps, ft)
                elseif ft isa Expr && ft.head == :curly
                    inner = ft.args[2]
                    if inner isa Symbol && inner in keys(type_fields)
                        push!(deps, inner)
                    end
                end
            end
            if deps ⊆ placed
                push!(ordered, tname => fields)
                push!(placed, tname)
                delete!(remaining, tname)
                progress = true
            end
        end
        if !progress
            for (tname, fields) in remaining
                push!(ordered, tname => fields)
            end
            break
        end
    end

    return ordered
end

# ---------------------------------------------------------------------------
# Code generation via Core.eval
# ---------------------------------------------------------------------------

"""Generate an @enum type with StructTypes JSON serialization in the given module."""
function generate_enum!(mod::Module, name::Symbol, members::Vector{Pair{Symbol,String}})
    member_syms = [m.first for m in members]
    fwd_name = Symbol("_", uppercase(string(name)), "_TO_STR")
    rev_name = Symbol("_STR_TO_", uppercase(string(name)))

    Core.eval(
        mod,
        Expr(:macrocall, Symbol("@enum"), LineNumberNode(0), name, member_syms...),
    )
    Core.eval(mod, Expr(:export, name, member_syms...))

    fwd_pairs = [:($(m.first) => $(m.second)) for m in members]
    Core.eval(mod, :(const $fwd_name = Dict{$name,String}($(fwd_pairs...))))

    rev_pairs = [:($(m.second) => $(m.first)) for m in members]
    Core.eval(mod, :(const $rev_name = Dict{String,$name}($(rev_pairs...))))

    Core.eval(mod, :(StructTypes.StructType(::Type{$name}) = StructTypes.StringType()))
    Core.eval(mod, :(function StructTypes.construct(::Type{$name}, s::String)
        return $rev_name[s]
    end))
    Core.eval(mod, :(function StructTypes.construct(::Type{$name}, sym::Symbol)
        return $rev_name[String(sym)]
    end))
    Core.eval(mod, :(function Base.string(x::$name)
        return $fwd_name[x]
    end))
    Core.eval(mod, :(function JSON3.write(io::IO, x::$name)
        return JSON3.write(io, $fwd_name[x])
    end))
    return nothing
end

"""Generate a @kwdef struct with StructTypes.Struct() and camelCase name mapping."""
function generate_struct!(mod::Module, name::Symbol, fields)
    field_exprs = Expr[]
    for f in fields
        jl_name = f.jl_name
        jl_type = f.type
        if f.required
            push!(field_exprs, :($jl_name::$jl_type))
        else
            push!(field_exprs, Expr(:(=), :($jl_name::Union{$jl_type,Nothing}), :nothing))
        end
    end

    struct_body = Expr(:block, field_exprs...)
    struct_expr = Expr(
        :macrocall,
        Expr(:., :Base, QuoteNode(Symbol("@kwdef"))),
        LineNumberNode(0),
        Expr(:struct, false, name, struct_body),
    )
    Core.eval(mod, struct_expr)

    Core.eval(mod, Expr(:export, name))

    Core.eval(mod, :(StructTypes.StructType(::Type{$name}) = StructTypes.Struct()))

    name_pairs = Tuple{Symbol,Symbol}[]
    for f in fields
        camel = Symbol(f.json_name)
        if camel != f.jl_name
            push!(name_pairs, (f.jl_name, camel))
        end
    end
    if !isempty(name_pairs)
        pairs_expr = Expr(
            :tuple,
            [Expr(:tuple, QuoteNode(p[1]), QuoteNode(p[2])) for p in name_pairs]...,
        )
        Core.eval(mod, :(StructTypes.names(::Type{$name}) = $pairs_expr))
    end
    return nothing
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

"""
    generate_types!(mod, schema_dir, enum_registry, nested_type_names, registry_name)

Read all OCPP JSON schemas from `schema_dir` and generate enums, structs,
and an action registry in the given module.

- `enum_registry`: sorted value vectors → (EnumTypeName, member_prefix)
- `nested_type_names`: JSON property name → Julia type name for shared sub-types
- `registry_name`: Symbol for the action registry constant (e.g. :V16_ACTIONS)
"""
function generate_types!(
    mod::Module,
    schema_dir::String,
    enum_registry::Dict{Vector{String},Tuple{Symbol,String}},
    nested_type_names::Dict{String,Symbol},
    registry_name::Symbol,
)
    schemas = read_schemas(schema_dir)

    # Build reverse lookup: sorted enum values → enum type name
    enum_lookup = Dict{Vector{String},Symbol}()
    for (values, (name, _)) in enum_registry
        enum_lookup[values] = name
    end

    # 1. Generate enums
    enum_defs = collect_enums(schemas, enum_registry)
    for (ename, members) in enum_defs
        generate_enum!(mod, ename, members)
    end

    # 2. Generate shared nested types (dependency-ordered)
    nested = collect_nested_types(schemas, enum_lookup, nested_type_names)
    for (tname, fields) in nested
        generate_struct!(mod, tname, fields)
    end

    # 3. Generate action payload structs
    action_names = String[]
    for (title, schema) in schemas
        struct_name = Symbol(title)
        if any(p -> p.first == struct_name, nested)
            continue
        end

        fields = struct_fields_from_schema(schema, enum_lookup, nested_type_names)
        generate_struct!(mod, struct_name, fields)

        base = if endswith(title, "Response")
            replace(title, "Response" => "")
        elseif endswith(title, "Request")
            replace(title, "Request" => "")
        else
            title
        end
        if base ∉ action_names
            push!(action_names, base)
        end
    end

    # 4. Generate action registry
    sort!(action_names)
    registry_pairs = Expr[]
    for action in action_names
        req_sym = Symbol(action * "Request")
        resp_sym = Symbol(action * "Response")
        push!(registry_pairs, :($action => (request = $req_sym, response = $resp_sym)))
    end

    Core.eval(
        mod,
        :(
            const $registry_name =
                Dict{String,@NamedTuple{request::DataType,response::DataType}}(
                    $(registry_pairs...),
                )
        ),
    )
    Core.eval(mod, :(export $registry_name, request_type, response_type))

    Core.eval(
        mod,
        :(
            function request_type(action::String)
                haskey($registry_name, action) ||
                    throw(ArgumentError("Unknown OCPP action: \$action"))
                return $registry_name[action].request
            end
        ),
    )
    Core.eval(
        mod,
        :(
            function response_type(action::String)
                haskey($registry_name, action) ||
                    throw(ArgumentError("Unknown OCPP action: \$action"))
                return $registry_name[action].response
            end
        ),
    )

    return nothing
end
