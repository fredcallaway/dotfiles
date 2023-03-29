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

function execute(cmd::Cmd)
  out = Pipe()
  err = Pipe()

  process = run(pipeline(ignorestatus(cmd), stdout=out, stderr=err))
  close(out.in)
  close(err.in)
  stdout = @async String(read(out))
  stderr = @async String(read(err))
  (
    stdout = String(read(out)),
    stderr = String(read(err)),
    code = process.exitcode
  )
end

execute(cmd::String) = execute(`bash -c $cmd`)

import REPL
import REPL.LineEdit

const mykeys = Dict{Any,Any}(
    "^o" => (s,o...)->(LineEdit.edit_insert(s, " |> ")),
    "^n" => (s,o...) -> begin
        LineEdit.edit_insert(s, "include(\"\")")
        LineEdit.edit_move_left(s)
        LineEdit.edit_move_left(s)
    end,
)

try
    import JLFzf
    mykeys["^r"] = function (s, o, c)
        line = JLFzf.inter_fzf(JLFzf.read_repl_hist(),
        "--read0",
        "--tiebreak=index",
        "--height=30%");
        JLFzf.insert_history_to_repl(s, line)
    end
    mykeys["^n"] = function (s, o, c)
        file = JLFzf.inter_fzf(execute("fd .*\\.jl").stdout, "--height=30%")
        LineEdit.edit_insert(s, "include(\"$file\")")
        LineEdit.commit_line(s)
    end
catch
end

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
