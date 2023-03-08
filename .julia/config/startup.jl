using Distributed
try
   using Infiltrator
catch
   println("Infiltrator not found")
end
try
   @everywhere using AbbreviatedStackTraces
catch
   println("AbbreviatedStackTraces not found")
end

hist_file = joinpath(pwd(), ".julia_history")
if isfile(hist_file)
    println("Using local history")
    ENV["JULIA_HISTORY"] = hist_file
end

using Pkg
if isfile("Project.toml") && isfile("Manifest.toml")
    Pkg.activate(".")
end


import REPL
import REPL.LineEdit

const mykeys = Dict{Any,Any}(
    # Up Arrow
    "^o" => (s,o...)->(LineEdit.edit_insert(s, " |> ")),
)

function customize_keys(repl)
    repl.interface = REPL.setup_interface(repl; extra_repl_keymap = mykeys)
end

atreplinit(customize_keys)



# fix bug in this function
#function Base._simplify_include_frames(trace)
#    kept_frames = trues(length(trace))
#    first_ignored = nothing
#    for i in length(trace):-1:1
#        frame::Base.StackFrame, _ = trace[i]
#        mod = parentmodule(frame)
#        if first_ignored === nothing
#            if mod === Base && frame.func === :_include
#                # Hide include() machinery by default
#                first_ignored = i
#            end
#        else
#            first_ignored = first_ignored::Int
#            # Hack: allow `mod==nothing` as a workaround for inlined functions.
#            # TODO: Fix this by improving debug info.
#            if mod in (Base,Core,nothing) && 1+first_ignored-i <= 5
#                if frame.func === :eval
#                    kept_frames[i:first_ignored] .= false
#                    first_ignored = nothing
#                end
#            else
#                # Bail out to avoid hiding frames in unexpected circumstances
#                first_ignored = nothing
#            end
#        end
#        i -= 1
#    end
#    if first_ignored !== nothing
#        kept_frames[1:first_ignored] .= false
#    end
#    return trace[kept_frames]
#end
