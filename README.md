# ReactGPT

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://asinghvi17.github.io/ReactGPT.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://asinghvi17.github.io/ReactGPT.jl/dev/)
[![Build Status](https://github.com/asinghvi17/ReactGPT.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/asinghvi17/ReactGPT.jl/actions/workflows/CI.yml?query=branch%3Amain)


This package was inspired by https://til.simonwillison.net/llms/python-react-pattern,
and is a simple implementation of the ReAct LLM pattern in Julia. 

The idea is that we can give LLMs access to the Internet, or to a database, 
or really any other resource, by defining a set of actions that the LLM can take.


# Usage

The `GPTReactor` struct is an implementation of this for GPT.  Here's a quick example:
```julia
julia> ENV["OPENAI_KEY"] = <<your key here>>

julia> using ReactGPT

julia> r = ReactGPT.GPTReactor()
...
shows some outout

julia> ReactGPT.query(r, "What does England share borders with?")
```

# Interface

We provide an [`AbstractAction`](@ref) interface, on which you can implement your own actions.  See the docstring for the exact implementation details.