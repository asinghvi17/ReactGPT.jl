
"""
    AbstractAction

This is the abstract type for all actions that the LLM can use.
Actions must satisfy the action interface, i.e., implement the 
following methods:

- `action_invocation(action::AbstractAction)`: returns a String describing how the action is invoked.  In future, this should return a regex.
- `describe_action(action::AbstractAction)`: returns a string describing the action, which is fed into the intitial prompt to the LLM. 
- `execute_action(action::AbstractAction, args::AbstractString)`: executes the action, and returns a String which is the response to that action.
"""
abstract type AbstractAction end

"""
    action_invocation(action::AbstractAction)

Returns a String describing how the action is invoked.  In future, this should return a regex.
"""
function action_invocation(action::AbstractAction)
    error("describe_action not implemented for $(typeof(action))")
end

"""
    describe_action(action::AbstractAction)

Returns a string describing the action, which is fed into the intitial prompt to the LLM. 
"""
function describe_action(action::AbstractAction)
    error("describe_action not implemented for $(typeof(action))")
end

"""
    execute_action(action::AbstractAction, args::AbstractString)

Executes the action, and returns a String which is the response to that action.
The arguments must always be typed as `AbstractString`s, in order to accomodate
SubStrings parsed from the LLM's response.
"""
function execute_action(action::AbstractAction, args::AbstractString)
    error("execute_action not implemented for $(typeof(action))")
end


# Wikipedia action

"""
    WikipediaAction()

Query Wikipedia directly.
"""
struct WikipediaAction <: AbstractAction
end

action_invocation(action::WikipediaAction) = "Wikipedia"

function describe_action(action::WikipediaAction)
    """
    Wikipedia:
    e.g. Wikipedia: Albert Einstein
    Returns a summary from searching Wikipedia.
    """
end

function execute_action(action::WikipediaAction, args::AbstractString)
    # execute the HTTP request to Wikipedia's API
    response = HTTP.request(
        "GET",
        "https://en.wikipedia.org/w/api.php";
        query = [
            "action" => "query",
            "list" => "search",
            "srsearch" => args,
            "format" => "json",
            "exsentences" => "10",
            "exsectionformat" => "wiki",
        ]
    )

    # parse the request as JSON
    content = JSON3.read(response.body)
    
    # pick the first result from the query, and get its snippet text
    snippet = content["query"]["search"][begin]["snippet"]
    # remove the HTML span tags
    snippet = replace(snippet, r"<span.*?>|</span>" => "")
    return snippet
end

# A more general MediaWiki action

"""
    MediaWikiAction(; api_url = "https://en.wikipedia.org/w/api.php", name = "Wikipedia")

Query any MediaWiki website.
"""
Base.@kwdef struct MediaWikiAction <: AbstractAction
    api_url::String = "https://en.wikipedia.org/w/api.php"
    name::String = "Wikipedia"
end

action_invocation(action::MediaWikiAction) = action.name

function describe_action(action::MediaWikiAction)
    """
    $(action.name):
    e.g. $(action.name): Albert Einstein
    Returns a summary from searching $(action.name).
    """
end

function execute_action(action::MediaWikiAction, args::AbstractString)
    # execute the HTTP request to Wikipedia's API
    response = HTTP.request(
        "GET",
        action.api_url;
        query = [
            "action" => "query",
            "list" => "search",
            "srsearch" => args,
            "format" => "json",
            "exsentences" => "10",
            "exsectionformat" => "wiki",
        ]
    )

    # parse the request as JSON
    content = JSON3.read(response.body)
    
    # pick the first result from the query, and get its snippet text
    snippet = content["query"]["search"][begin]["snippet"]
    # remove the HTML span tags
    snippet = replace(snippet, r"<span.*?>|</span>" => "")
    return snippet
end

