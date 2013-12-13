open Core.Std
open Async.Std


module Message : OFProtocol.OFMessage
  with module Header = OpenFlow0x01.Message.Header
   and type m   = OpenFlow0x01.Message.t
   and type xid = OpenFlow0x01.xid
   and type t   = (OpenFlow0x01.xid * OpenFlow0x01.Message.t)

module Protocol : Typed_tcp.S
  with type Client_message.t = Message.t
   and type Server_message.t = Message.t

module ClientTable : Map.S
  with type Key.t = Protocol.Client_id.t

include OFController.S
  with type m = Message.t
   and type c = Protocol.Client_id.t
   and type s = OpenFlow0x01.SwitchFeatures.t
