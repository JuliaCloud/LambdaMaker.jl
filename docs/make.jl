using Documenter, LambdaMaker

makedocs(;
    modules=[LambdaMaker],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/invenia/LambdaMaker.jl/blob/{commit}{path}#L{line}",
    sitename="LambdaMaker.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
)

deploydocs(; repo="github.com/invenia/LambdaMaker.jl")
