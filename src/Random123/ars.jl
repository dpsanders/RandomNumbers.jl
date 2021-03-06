import Base: copy, copy!, ==
import RandomNumbers: gen_seed, union_uint, seed_type, unsafe_copy!, unsafe_compare

"""
```julia
ARS1x{R} <: R123Generator1x{UInt128}
ARS1x([seed, R=7])
```

ARS1x is one kind of ARS Counter-Based RNGs. It generates one `UInt128` number at a time.

`seed` is an `Integer` which will be automatically converted to `UInt128`.

`R` denotes to the Rounds which should be at least 1 and no more than 10. With 7 rounds (by default), it has
a considerable safety margin over the minimum number of rounds with no known statistical flaws, but still has
excellent performance.

Only available when [`R123_USE_AESNI`](@ref).
"""
mutable struct ARS1x{R} <: R123Generator1x{UInt128}
    x::UInt128
    key::UInt128
    ctr::UInt128
end

function ARS1x(seed::Integer=gen_seed(UInt128), R::Integer=7)
    @assert 1 <= R <= 10
    r = ARS1x{Int(R)}(0, 0, 0)
    srand(r, seed)
end

function srand(r::ARS1x, seed::Integer=gen_seed(UInt128))
    r.key = seed % UInt128
    r.ctr = 0
    random123_r(r)
    r
end

@inline seed_type{R}(::Type{ARS1x{R}}) = UInt128

for R = 1:10
    @eval @inline function ars1xm128i(r, ::Type{Val{$R}}, ctr, key)
        p1 = Ptr{UInt128}(pointer_from_objref(ctr))
        p2 = Ptr{UInt128}(pointer_from_objref(key))
        p = Ptr{UInt128}(pointer_from_objref(r))
        ccall(($("ars1xm128i$R"), librandom123), Void, (
        Ptr{UInt128}, Ptr{UInt128}, Ptr{UInt128}
        ), p1, p2, p)
        unsafe_load(p, 1)
    end
end

copy!{R}(dest::ARS1x{R}, src::ARS1x{R}) = unsafe_copy!(dest, src, UInt128, 3)

copy{R}(src::ARS1x{R}) = ARS1x{R}(src.x, src.key, src.ctr)

=={R}(r1::ARS1x{R}, r2::ARS1x{R}) = unsafe_compare(r1, r2, UInt128, 3)

@inline function random123_r{R}(r::ARS1x{R})
    ars1xm128i(r, Val{R}, r.ctr, r.key)
    (r.x,)
end

"""
```julia
ARS4x{R} <: R123Generator4x{UInt32}
ARS4x([seed, R=7])
```

ARS4x is one kind of ARS Counter-Based RNGs. It generates four `UInt32` numbers at a time.

`seed` is a `Tuple` of four `Integer`s which will all be automatically converted to `UInt32`.

`R` denotes to the Rounds which must be at least 1 and no more than 10. With 7 rounds (by default), it has a
considerable safety margin over the minimum number of rounds with no known statistical flaws, but still has
excellent performance.

Only available when [`R123_USE_AESNI`](@ref).
"""
mutable struct ARS4x{R} <: R123Generator4x{UInt32}
    x1::UInt32
    x2::UInt32
    x3::UInt32
    x4::UInt32
    key::UInt128
    ctr1::UInt128
    p::Int
end

function ARS4x(seed::NTuple{4, Integer}=gen_seed(UInt32, 4), R::Integer=7)
    @assert 1 <= R <= 10
    r = ARS4x{Int(R)}(0, 0, 0, 0, 0, 0, 0)
    srand(r, seed)
end

function srand(r::ARS4x, seed::NTuple{4, Integer}=gen_seed(UInt32, 4))
    r.key = union_uint(map(x -> x % UInt32, seed))
    r.ctr1 = 0
    p = 0
    random123_r(r)
    r
end

@inline seed_type{R}(::Type{ARS4x{R}}) = NTuple{4, UInt32}

@inline function random123_r{R}(r::ARS4x{R})
    ars1xm128i(r, Val{R}, r.ctr1, r.key)
    (r.x1, r.x2, r.x3, r.x4)
end

function copy!{R}(dest::ARS4x{R}, src::ARS4x{R})
    unsafe_copy!(dest, src, UInt128, 3)
    dest.p = src.p
    dest
end

copy{R}(src::ARS4x{R}) = ARS4x{R}(src.x1, src.x2, src.x3, src.x4, src.key, src.ctr1, src.p)

=={R}(r1::ARS4x{R}, r2::ARS4x{R}) = unsafe_compare(r1, r2, UInt128, 3) && r1.p == r2.p
