using ReactGPT
using Documenter

DocMeta.setdocmeta!(ReactGPT, :DocTestSetup, :(using ReactGPT); recursive=true)

makedocs(;
    modules=[ReactGPT],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    repo="https://github.com/asinghvi17/ReactGPT.jl/blob/{commit}{path}#{line}",
    sitename="ReactGPT.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://asinghvi17.github.io/ReactGPT.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/asinghvi17/ReactGPT.jl",
    devbranch="main",
)
