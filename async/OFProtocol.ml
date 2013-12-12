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

module Make(OFM : OFMessage)
  : (Typed_tcp.S
      with type Client_message.t = OFM.t
       and type Server_message.t = OFM.t) =
  Typed_tcp.Make(struct
    module Client_message = OFM
    module Server_message = OFM

    module Transport = struct
      type t = Reader.t * Writer.t

      let create (r : Reader.t) (w : Writer.t) = return (r, w)
      let close ((_, w) : t) = Writer.close w
      let flushed_time ((_, w) : t) = Writer.flushed_time w

      let read ((r, _) : t) =
        let ofhdr_str = String.create OFM.Header.size in
        Reader.really_read r ofhdr_str
        >>= function
          | `Eof _ -> return `Eof
          | `Ok ->
            let hdr = OFM.Header.parse ofhdr_str in
            let body_len = OFM.Header.len hdr - OFM.Header.size in
            let body_buf = String.create body_len in
            Reader.really_read r body_buf
            >>= function
              | `Eof _ -> return `Eof
              | `Ok -> return (`Ok (OFM.parse hdr body_buf))

      let write ((_, w) : t) (xid, msg) =
        Writer.write w (OFM.marshal xid msg)
    end
  end)
