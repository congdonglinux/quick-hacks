(*
  Implementation for the naturals datatype.

  Builtin booleans.
*)


type nat = bool

let zero = true
let suc = not

let add = (=)

let mul = (||)
