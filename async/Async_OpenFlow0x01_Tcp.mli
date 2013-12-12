(** A "typed TCP" connection, where messages are OpenFlow 1.0 messages

This module can be used to create controllers or software switches. It only
does serialization and nothing else. So, the input and output streams include
hello messages, echo messages, etc. *)
open Core.Std
open Async.Std
open OpenFlow0x01

module OF0x01Message : OFProtocol.OFMessage

module Tcp : Typed_tcp.S
  with type Client_message.t = OF0x01Message.t
   and type Server_message.t = OF0x01Message.t
