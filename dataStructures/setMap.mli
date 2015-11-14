(** Our own implementattion of Set and Map

Purely functionnal. Nothing there raises any exception. *)

module type OrderedType =
  sig
    type t
    val compare : t -> t -> int
  end

module type Set =
  sig
    type elt
    type t

    val empty: t
    val is_empty: t -> bool
    val singleton: elt -> t
    val is_singleton: t -> bool

    val add: elt -> t -> t
    val add_with_logs:  ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * t 
																				   
    val remove: elt -> t -> t
    val remove_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * t 			      
   
    val split: elt -> t -> (t * bool * t)
    val union: t -> t -> t
    val inter: t -> t -> t
    val minus: t -> t -> t
    (** [minus a b] contains elements of [a] that are not in [b] *)
    val diff: t -> t -> t
    (** [diff a b] = [minus (union a b) (inter a b)] *)
    val union_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t 
    val inter_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t
    val diff_with_logs:  ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t
(*    val split_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * ( t * bool * t)*)

  
    val cardinal: t -> int

    val mem: elt -> t -> bool
    val exists: (elt -> bool) -> t -> bool
    val filter: (elt -> bool) -> t -> t
    val for_all: (elt -> bool) -> t -> bool
    val partition: (elt -> bool) -> t -> t * t

    val compare: t -> t -> int
    val equal: t -> t -> bool
    val subset: t -> t -> bool

    val iter: (elt -> unit) -> t -> unit
    val fold: (elt -> 'a -> 'a) -> t -> 'a -> 'a
    val fold_inv: (elt -> 'a -> 'a) -> t -> 'a -> 'a

    val elements: t -> elt list

    val choose: t -> elt option
    val min_elt: t -> elt option
    val max_elt: t -> elt option
  end

module type Map =
  sig
    type elt
    type set
    type +'a t

    val empty: 'a t
    val is_empty: 'a t -> bool
    val size: 'a t -> int
    val root: 'a t -> (elt * 'a) option
    val max_key: 'a t -> elt option

    val add: elt -> 'a -> 'a t -> 'a t
    val remove: elt -> 'a t -> 'a t
    val pop: elt -> 'a t -> ('a option * 'a t)
    val merge: 'a t -> 'a t -> 'a t
    val min_elt: (elt -> 'a -> bool) -> 'a t -> elt option
    val find_option: elt -> 'a t -> 'a option
    val find_default: 'a -> elt -> 'a t -> 'a
    val find_option_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> 'a t -> 'error * 'a option
    val find_default_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a -> elt -> 'a t -> 'error * 'a
    val mem:  elt -> 'a t -> bool
    val diff: 'a t -> 'a t -> 'a t * 'a t
    val union: 'a t -> 'a t -> 'a t
    val update: 'a t -> 'a t -> 'a t
    val diff_pred: ('a -> 'a -> bool) -> 'a t -> 'a t -> 'a t * 'a t
    val add_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> 'a -> 'a t -> 'error * 'a t
    val remove_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> 'a t -> 'error * 'a t

    
    val join_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a t -> elt -> 'a -> 'a t -> 'error * 'a t
    val split_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> 'a t -> 'error * ('a t * 'a option * 'a t)
    val update_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error  -> 'a t -> 'a t -> 'error * 'a t    
    val map2_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> 'a -> 'error * 'a) -> ('parameters -> 'error -> 'a -> 'error *  'a) -> ('parameters -> 'error -> 'a -> 'a -> 'error * 'a) -> 'a t -> 'a t -> 'error * 'a t
    val map2z_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> 'a -> 'a -> 'error * 'a) -> 'a t -> 'a t -> 'error * 'a t 
    val fold2z_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> elt -> 'a  -> 'b  -> 'c   -> ('error * 'c)) -> 'a t -> 'b t -> 'c -> 'error * 'c 
    val fold2_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> elt -> 'a   -> 'c  -> 'error * 'c) -> ('parameters -> 'error -> elt -> 'b  ->  'c  -> 'error * 'c) -> ('parameters -> 'error -> elt -> 'a -> 'b  -> 'c  -> 'error * 'c) ->  'a t -> 'b t -> 'c -> 'error * 'c 
  
   
    val fold2_sparse_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> elt -> 'a  -> 'b  -> 'c  -> ('error * 'c)) ->  'a t -> 'b t -> 'c -> 'error * 'c
    val iter2_sparse_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('parameters -> 'error -> elt -> 'a  -> 'b  -> 'error)->  'a t -> 'b t -> 'error 
(*    val diff_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a t -> 'a t -> 'error * 'a t * 'a t 
    val diff_pred_with_logs: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> ('a -> 'a -> bool) -> 'a t -> 'a t -> 'error * 'a t * 'a t 
    val merge_with_logs : ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a t -> 'a t -> 'error * 'a t
    val union_with_logs : ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a t -> 'a t -> 'error * 'a t
    val fold_map_restriction_with_logs:  ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> (elt -> 'a -> ('error * 'b) -> ('error* 'b)) -> set -> 'a t -> 'b -> 'error * 'b 
 *)
								   
    val iter: (elt -> 'a -> unit) -> 'a t -> unit
    val fold: (elt -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
    val monadic_fold2:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'c -> ('method_handler * 'c)) ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'c -> ('method_handler * 'c)) ->
      ('parameters -> 'method_handler ->
       elt -> 'b -> 'c -> ('method_handler * 'c)) ->
      'a t -> 'b t -> 'c -> ('method_handler * 'c)
    val monadic_fold2_sparse:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'c -> ('method_handler * 'c)) ->
      'a t -> 'b t -> 'c -> ('method_handler * 'c)
    val monadic_iter2_sparse:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'method_handler) ->
      'a t -> 'b t -> 'method_handler
    val monadic_fold_restriction:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> ('method_handler * 'b)) ->
      set -> 'a t -> 'b -> 'method_handler * 'b

    val mapi: (elt -> 'a -> 'b) -> 'a t -> 'b t
    val map: ('a -> 'b) -> 'a t -> 'b t
    val map2: ('a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t

    val for_all: (elt -> 'a -> bool) -> 'a t -> bool
    val compare: ('a -> 'a -> int) -> 'a t -> 'a t -> int
    val equal: ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val bindings : 'a t -> (elt * 'a) list
  end

module type S = sig
    type elt
    module Set : Set with type elt = elt
    module Map : Map with type elt = elt and type set = Set.t
  end

module Make(Ord:OrderedType): S with type elt = Ord.t
