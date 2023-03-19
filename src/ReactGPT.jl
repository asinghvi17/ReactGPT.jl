"""
    ReactGPT

This package was inspired by https://til.simonwillison.net/llms/python-react-pattern,
and is a simple implementation of the ReAct LLM pattern in Julia. 

The idea is that we can give LLMs access to the Internet, or to a database, 
or really any other resource, by defining a set of actions that the LLM can take.

Theoretically, one could have an `EvalAction` which lets the LLM run arbitrary Julia code
on your computer.  Please don't do this - Julia isn't sandboxed, and the risk that 
the model accidentally runs `rm("/"; force = true)` or some similarly destructive
action is really quite high.

# Usage

# Interface

We provide an [`AbstractAction`](@ref) interface which handles most of the stuff.

"""
module ReactGPT

using OpenAI
using HTTP, JSON3
using DocStringExtensions # for the prompt docstring extension

include("actions.jl")
export AbstractAction, describe_action, execute_action
export WikipediaAction

struct GPTReactor
    params::NamedTuple
    messages::Vector{Dict}
    actions::Vector{<: AbstractAction}
end

function Base.show(io::IO, reactor::GPTReactor)
    safe_params = (; reactor.params..., auth_key = "XXX",)
    println(io, "GPTReactor$(safe_params)")
    println(io, "with actions:")
    show(io, reactor.actions)
    println()
    println(io, "and $(length(reactor.messages)) messages")
end

function GPTReactor(; 
        actions = [WikipediaAction(),], 
        default_example_session = true, 
        model = "gpt-3.5-turbo",
        auth_key = ENV["OPENAI_KEY"],
        chatgpt_params...
    )

    initial_prompt = """
    You run in a loop of Thought, Action, PAUSE, Observation.
    At the end of the loop you output an Answer.
    Use Thought to describe your thoughts about the question you have been asked.
    Use Action to run one of the actions available to you - then return PAUSE.
    Observation will be the result of running those actions.

    Your available actions are:

    $(join(describe_action.(actions), "\n\n\n"))

    """

    if WikipediaAction in typeof.(actions)
        initial_prompt *= """

            Always look things up on Wikipedia if you have the opportunity to do so.

        """
    end

    if default_example_session
        initial_prompt *= """

        Example session:

        Question: What is the capital of France?
        Thought: I should look up France on Wikipedia
        Action: wikipedia: France
        PAUSE

        You will be called again with this:

        Observation: France is a country. The capital is Paris.

        You then output:

        Answer: The capital of France is Paris

        You don't need to ask any questions now, please wait for the user to prompt you.

        """
    end

    messages = Dict{Symbol, Any}[]

    reactor = GPTReactor((; model, auth_key, chatgpt_params...), messages, actions)

    execute!(reactor, initial_prompt; role = "system", chatgpt_params...)

    return reactor
end

function execute!(r::GPTReactor, message::String; role = "user", show = true, model = "", auth_key = ENV["OPENAI_KEY"], chatgpt_params...)

    push!(r.messages, Dict(:role => role, :content => message))

    response = OpenAI.create_chat(r.params.auth_key, r.params.model, r.messages; chatgpt_params...)

    if response.status != 200
        error("Error creating chat: $(response.status) $(response.body)")
    end

    return_message = response.response.choices[1].message.content

    push!(r.messages, Dict(:role => :assistant, :content => return_message))

    if show
        printstyled(role; color = :green, bold = true)
        println()
        println(message)
        println()
        printstyled("ChatGPT:\n", color = :blue, bold = true)
        println(return_message)
        println()
    end

    return return_message

end

function query(reactor::GPTReactor, question::String; maxiters = 5)
    next_prompt = question
    
    action_invocations = lowercase.(action_invocation.(reactor.actions))

    for i in 1:maxiters
        response = execute!(reactor, next_prompt; role = "user", show = true)

        action_matches = match.((r"^Action: (\w+): (.*)$",), split(response, "\n"))
        action_match = findfirst(!isnothing, action_matches)

        if action_match === nothing
            println("No action found in response.")
            break
        else
            action_match = action_matches[action_match]
        end

        action_index = findfirst(==(lowercase(action_match[1])), action_invocations)
        
        if isnothing(action_index)
            if occursin("Answer", response)
                println("Answer found.")
                break
            end
            printstyled("Action not found: $(action_match[1])."; color = :red)
            println()
            break
        end

        # execute the action
        action = reactor.actions[action_index]
        action_result = execute_action(action, action_match[2])
        next_prompt = "Observation: " * action_result

    end

    return reactor
end


end # module
