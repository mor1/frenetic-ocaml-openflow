open Core.Std
open Async.Std
open OpenFlow0x01

module OF0x01Message = struct
  module Header = Message.Header

  type m = Message.t
  type xid = OpenFlow0x01.xid

  type t = (xid * m) sexp_opaque with sexp

  let parse h s = Message.parse h s
  let marshal id m = Message.marshal id m
  let to_string m = Message.to_string m
end

module Tcp = OFProtocol.Make(OF0x01Message)
