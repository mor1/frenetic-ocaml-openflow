open Async.Std
open Core.Std


module type S = sig
  type t
  type s
  type c
  type m

  val create
    :  int
    -> unit
    -> t Deferred.t

  val listen
    : t -> [`SwitchUp of c * s | `SwitchDown of c | `Message of c * m] Pipe.Reader.t

  val close : t -> c -> unit
  val has_switch : t -> c -> bool
  val flushed_time
    : t -> c -> [ `Switch_not_found | `Flushed of Time.t Deferred.t ]
  val send : t -> c -> m -> [`Sent of Time.t | `Drop of exn] Deferred.t
  val send_to_all : t -> m -> unit
  val switch_addr_port : t -> c -> (Unix.Inet_addr.t * int) option
end
