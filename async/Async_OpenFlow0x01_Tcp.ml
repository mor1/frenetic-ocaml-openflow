open Core.Std
open Async.Std
open OpenFlow0x01

module OFMessage = struct
  type t = (xid * Message.t) sexp_opaque with sexp
end

module OpenFlowArg = struct

  module Client_message = OFMessage

  module Server_message = OFMessage

  module Transport = struct
  
    type t = Reader.t * Writer.t

    let create (r : Reader.t) (w : Writer.t) = return (r, w)

    let close ((_, w) : t) = Writer.close w

    let flushed_time ((_, w) : t) = Writer.flushed_time w

    let read ((r, _) : t) =
      let ofhdr_str = String.create Message.Header.size in
      Reader.really_read r ofhdr_str >>= function
      | `Eof _ -> return `Eof
      | `Ok -> 
      let hdr = Message.Header.parse ofhdr_str in
      let body_len = Message.Header.len hdr - Message.Header.size in
      let body_buf = String.create body_len in
      Reader.really_read r body_buf >>= function
      | `Eof _ -> return `Eof
      | `Ok -> return (`Ok (Message.parse hdr body_buf))

    let write ((_, w) : t) (xid, msg) =
      Writer.write w (Message.marshal xid msg)

  end

end

module Tcp = Typed_tcp.Make (OpenFlowArg)