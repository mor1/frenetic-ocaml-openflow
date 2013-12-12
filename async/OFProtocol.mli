open Async.Std
open Core.Std

module type OFMessage = sig
  module Header : sig
    type t

    val size : int
    val len : t -> int

    val parse : string -> t
    val to_string : t -> string
  end

  type m
  type xid

  type t = (xid * m)
  include Sexpable with type t := t

  val parse : Header.t -> string -> t
  val marshal : xid -> m -> string

  val to_string : m -> string
end

module Make(OFM : OFMessage) : Typed_tcp.S
  with type Client_message.t = OFM.t
  with type Server_message.t = OFM.t
