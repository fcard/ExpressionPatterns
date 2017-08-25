module MetaModule
using  ...Dispatch.Applications
using  ...Dispatch.TopMetaTables
using  ...Dispatch
import Base.Meta: quot
export @metamodule

const MM = Dispatch.Applications.MACROMETHODS
const MF = Dispatch.Applications.METAFUNCTIONS

#-----------------------------------------------------------------------------------
# @metamodule
#-----------------------------------------------------------------------------------

@macromethod metamodule(:R{:import,    *{path}})  esc(importcode(path, __module__))
@macromethod metamodule(:R{:importall, *{path}})  esc(importallcode(path))
@macromethod metamodule(:R{:export,    *{names}}) esc(exportcode(names, __module__))

@macromethod metamodule(:R{:toplevel}) nothing
@macromethod metamodule(:R{:toplevel,x,*{xs}}) esc(quote
  @metamodule $x
  @metamodule $(Expr(:toplevel, xs...))
end)

#-----------------------------------------------------------------------------------
# Code generation.
#-----------------------------------------------------------------------------------

function importcode(path, mod)
  name = last(path)
  top  = gettable(path[end])
  quote
    import $(path...)
    import $(path[1:end-1]...).($(path[end-1]))
    $(import_metatable!)($top, $(quot(name)), $(path[end-1]), $mod)
  end
end

exportcode(names, mod) = quote

  eval(:(export $($names...)))
  for name in $names
    top = $gettable(name)
    $(export_metatable!)(top, name, $mod)
  end
end


function importallcode(path)
  M = path[end]
  quote

    eval(Expr(:import, $path..., $(quot(M))))

    metafun_exports  = $metatable_exports($MM, $M)
    macromet_exports = $metatable_exports($MF, $M)

    for exp in $union(metafun_exports, macromet_exports)
      imp = Expr(:import, $vcat($path, exp)...)
      eval($macrocall_ex("@metamodule", imp))
    end
  end
end

#-----------------------------------------------------------------------------------
# Utility functions.
#-----------------------------------------------------------------------------------

gettable(name) =
  startswith(string(name), "@") ? MM : MF

function macrocall_ex(name, args...)
  ex = :(@x $(args...))
  ex.args[1] = Symbol(name)
  ex
end

end
