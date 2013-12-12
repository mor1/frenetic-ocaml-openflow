(** A "typed TCP" connection, where messages are OpenFlow 1.0 messages

This module can be used to create controllers or software switches. It only
does serialization and nothing else. So, the input and output streams include
hello messages, echo messages, etc. *)
open Core.Std
open Async.Std
open OpenFlow0x01

module OFMessage : sig
  type t = (xid * Message.t)
end

module Tcp : Typed_tcp.S
  with module Client_message = OFMessage
   and module Server_message = OFMessage