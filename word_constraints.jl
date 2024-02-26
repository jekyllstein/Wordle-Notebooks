### A Pluto.jl notebook ###
# v0.19.39

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 98b31aa2-1b58-11ed-2476-87a9652f2d34
# ╠═╡ show_logs = false
using HTTP, ZipFile, DataFrames, CSV, PlutoUI

# ╔═╡ d87b02e1-4fa1-4136-859d-1f604c2958da
md"""
# Readme

The goal of this notebook is to see a list of words that fit certain constraints.  In particular the available constraints are word length, unique letters counts, and specific unique letters.  An example of a use case would be to see all 5 letter words that contain only 2 unique letters including 'a' and excluding all other vowels.

The final word list will depend on the dictionary selected.  There are 3 options from the most commonly used 25k words to a large dictionary of over 1.5M.
"""

# ╔═╡ 8fac8fcb-0221-4068-8587-def0c3cabea0
md"""
# Select Desired Word Properties
#### Word Length $(@bind n NumberField(1:10, 5))
"""

# ╔═╡ ef9b04ea-192b-421c-b359-9d35c0f55a74
md"""
# Matching Words
"""

# ╔═╡ 2407b067-d7a3-48d4-8582-a223bed373db
md"""
# Dependencies
"""

# ╔═╡ 7dab7d6d-8746-4266-976b-88c62e08e139
md"""
# Constants
"""

# ╔═╡ 82f6fe1c-0139-4375-8e28-a1d632ae0d35
const letters = collect('a':'z')

# ╔═╡ 862e3e4b-cfd3-438a-bc62-a197a776449a
const vowels = ['a', 'e', 'i', 'o', 'u', 'y']

# ╔═╡ 76107a99-7039-4f63-98a8-08f7092fb5d7
const consonants = setdiff(letters, vowels)

# ╔═╡ 23a3f6c9-0e72-4c70-bf86-e7dce14ab81c
md"""
#### Unique Letters $(@bind c NumberField(1:n, 2))

#### Required Letters 

Vowels 
$(@bind desiredvowels MultiCheckBox(vowels, select_all=true))

Consonants
$(@bind desiredconsonants MultiCheckBox(consonants, select_all=true))
"""

# ╔═╡ 8962b841-c043-4f4e-8573-c004a8d48acc
md"""
#### Forbidden Letters 

Vowels
$(@bind undesiredvowels MultiCheckBox(setdiff(vowels, desiredvowels), select_all=true))

Consonants
$(@bind undesiredconsonants MultiCheckBox(setdiff(consonants, desiredconsonants), select_all=true))
"""

# ╔═╡ e4ab6b70-7384-4564-95a9-3d2c2451e5e7
md"""
# Dynamic Variables
"""

# ╔═╡ c0b3d047-8b3c-45ef-9a16-ec1d15f5c172
md"""
# Functions
"""

# ╔═╡ 90074055-3d6c-4944-b9d9-dfebf88e8f90
checkword(word) = isempty(setdiff(Set(word), letters))

# ╔═╡ a04f64d6-3805-4597-b025-5ced7021c3cd
function parse_url_text(url, delim = "\r\n")
	data = String(HTTP.get(url).body)
	wordlist = split(data, delim)
	string.(filter(checkword, wordlist))
end

# ╔═╡ fd06a7d3-2fc6-4189-8cfe-45111728e54c
# ╠═╡ show_logs = false
const word_loaders = Dict([
	"Big_Word_list_1517k" => filter(checkword, dropmissing(CSV.read(ZipFile.Reader(IOBuffer(HTTP.get("https://www.keithv.com/software/wlist/wlist_match1.zip").body)).files[1], DataFrame, header=false, buffer_in_memory=true, footerskip = 5, skipto = 11, silencewarnings=true), 1)[!, 1]),
	"InfoChimps_350k" => parse_url_text("https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt"),
	"CommonWords_25k" => parse_url_text("https://raw.githubusercontent.com/dolph/dictionary/master/popular.txt", '\n')
])

# ╔═╡ 1932f5f2-3394-43cb-975b-6df0d468922c
md"""
Select Dictionary Word List $(@bind wordlist Select(collect(keys(word_loaders)), default = "CommonWords_25k"))
"""

# ╔═╡ 260cb3ed-9090-4517-8e11-f358982276a1
function check_key(desiredletters::Set{Char}, undesiredletters::Set{Char}, key::Set{Char})
#check to see if a key contains all the desired letters and none of the undesired lettres
	c1 = isempty(setdiff(desiredletters, key))
	c2 = isempty(intersect(undesiredletters, key))
	c1 && c2
end

# ╔═╡ c961807f-9d47-4625-bea9-48335701a0f7
function get_available_keys(desiredletters, undesiredletters, tbl_select)
	set1 = Set(desiredletters)
	set2 = Set(undesiredletters)
	filter(a -> check_key(set1, set2, a.unique_letters), keys(tbl_select))
end

# ╔═╡ ab2b13f6-79f0-4abe-8b79-02a650a0e0e2
function make_word_property_table(words)
	wordlength = length.(words)
	unique_letters = Set.(unique.(words))
	unique_count = length.(unique_letters)
	DataFrame(word = words, length = wordlength, unique_letters = unique_letters, unique_count = unique_count)
end

# ╔═╡ 5c1287f6-5fbd-4768-be66-7dbb67a2802b
const word_properties = Dict(k => make_word_property_table(word_loaders[k]) for k in keys(word_loaders))

# ╔═╡ ce352791-9680-44b0-84df-906b34253cc3
tbl_select = groupby(select(filter(a -> a.length == n && a.unique_count == c, word_properties[wordlist]), [:word, :unique_letters]), :unique_letters)

# ╔═╡ 2ee354c2-d9f5-4efc-b06a-c78180de20b7
availablekeys = get_available_keys(union(desiredvowels, desiredconsonants), union(undesiredvowels, undesiredconsonants), tbl_select)

# ╔═╡ ff76d227-043f-422f-a087-914ce9027b25
availablechars = isempty(availablekeys) ? Vector{Char}() : reduce(union, a.unique_letters for a in availablekeys) |> collect |> sort

# ╔═╡ 04d388d1-898d-4838-927d-3cd731887d4e
md"""
Unselect characters to remove matching words that contain that letter
$(@bind charselect MultiCheckBox(availablechars, default = availablechars, select_all=true))
"""

# ╔═╡ d628a50a-15e4-408e-a15c-14c1ff4aafe0
charset = Set(charselect)

# ╔═╡ cf1f1cbf-7772-436e-84b2-8d8a5a909f1a
keyselect = filter(k -> isempty(setdiff(k.unique_letters, charset)), availablekeys)

# ╔═╡ d181317e-c844-43da-812d-927a66f478a4
finalwordlist = isempty(keyselect) ? Vector{String}() : reduce(vcat, (collect(tbl_select[k].word) for k in keyselect))

# ╔═╡ a171f129-4847-4dba-a5f5-9a88fc18ac80
if isempty(finalwordlist)
	md"""
	No matching words
	"""
else
	Markdown.parse(reduce((a, b) -> "$a, $b", finalwordlist))
end

# ╔═╡ 26f8472a-886a-4401-9ea5-f4f59b2eb29b
function n_letter_words(n::Integer)
	filter(a -> length(a) == n, words)
end

# ╔═╡ 424b204f-35f1-4071-9021-8fc392d30af1
md"""
# Table of Contents Settings
"""

# ╔═╡ 85605b23-4beb-4baf-9317-0530bc11983b
PlutoUI.TableOfContents(title="Table of Contents", indent=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ZipFile = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"

[compat]
CSV = "~0.10.12"
DataFrames = "~1.6.1"
HTTP = "~1.10.2"
PlutoUI = "~0.7.58"
ZipFile = "~0.10.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.1"
manifest_format = "2.0"
project_hash = "99a19db354c719c89827c5d9abf5a3027376e6ac"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "c278dfab760520b8bb7e9511b968bf4ba38b7acc"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "2dc09997850d68179b69dafb58ae806167a32b1b"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.8"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "679e69c611fff422038e9e21e270c4197d49d918"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.12"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "59939d8a997469ee05c4b4944560a820f9ba0d73"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.4"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "c955881e3c981181362ae4088b35995446298b80"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.14.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "9c4708e3ed2b799e6124b5673a712dda0b596a9b"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1fb174f0d48fe7d142e1109a10636bc1d14f5ac2"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.17"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "ac7b73d562b8f4287c3b67b4c66a5395a19c1ae8"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.2"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60e3045590bd104a16fefb12836c00c0ef8c7f8c"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.13+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "71a22244e352aa8c5f0f2adde4150f62368a3f2e"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.58"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "88b895d13d53b5577fd53379d913b9ab9ac82660"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "0e7508ff27ba32f26cd459474ca2ede1bc10991f"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "54194d92959d8ebaa8e26227dbe3cdefcdcd594f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.3"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "f492b7fe1698e623024e873244f10d89c95c340a"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─d87b02e1-4fa1-4136-859d-1f604c2958da
# ╟─1932f5f2-3394-43cb-975b-6df0d468922c
# ╟─8fac8fcb-0221-4068-8587-def0c3cabea0
# ╟─23a3f6c9-0e72-4c70-bf86-e7dce14ab81c
# ╟─8962b841-c043-4f4e-8573-c004a8d48acc
# ╟─ef9b04ea-192b-421c-b359-9d35c0f55a74
# ╟─04d388d1-898d-4838-927d-3cd731887d4e
# ╟─a171f129-4847-4dba-a5f5-9a88fc18ac80
# ╟─2407b067-d7a3-48d4-8582-a223bed373db
# ╠═98b31aa2-1b58-11ed-2476-87a9652f2d34
# ╟─7dab7d6d-8746-4266-976b-88c62e08e139
# ╠═82f6fe1c-0139-4375-8e28-a1d632ae0d35
# ╠═862e3e4b-cfd3-438a-bc62-a197a776449a
# ╠═76107a99-7039-4f63-98a8-08f7092fb5d7
# ╠═fd06a7d3-2fc6-4189-8cfe-45111728e54c
# ╠═5c1287f6-5fbd-4768-be66-7dbb67a2802b
# ╟─e4ab6b70-7384-4564-95a9-3d2c2451e5e7
# ╠═d181317e-c844-43da-812d-927a66f478a4
# ╠═ce352791-9680-44b0-84df-906b34253cc3
# ╠═2ee354c2-d9f5-4efc-b06a-c78180de20b7
# ╠═ff76d227-043f-422f-a087-914ce9027b25
# ╠═d628a50a-15e4-408e-a15c-14c1ff4aafe0
# ╠═cf1f1cbf-7772-436e-84b2-8d8a5a909f1a
# ╟─c0b3d047-8b3c-45ef-9a16-ec1d15f5c172
# ╠═a04f64d6-3805-4597-b025-5ced7021c3cd
# ╠═90074055-3d6c-4944-b9d9-dfebf88e8f90
# ╠═260cb3ed-9090-4517-8e11-f358982276a1
# ╠═c961807f-9d47-4625-bea9-48335701a0f7
# ╠═ab2b13f6-79f0-4abe-8b79-02a650a0e0e2
# ╠═26f8472a-886a-4401-9ea5-f4f59b2eb29b
# ╟─424b204f-35f1-4071-9021-8fc392d30af1
# ╠═85605b23-4beb-4baf-9317-0530bc11983b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
