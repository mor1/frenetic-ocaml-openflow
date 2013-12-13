open Async.Std
open Core.Std
module OF0x01 = OpenFlow0x01

module Message = struct
  module Header = OF0x01.Message.Header

  type m = OF0x01.Message.t
  type xid = OF0x01.xid

  type t = (xid * m) sexp_opaque with sexp

  let parse h s = OF0x01.Message.parse h s
  let marshal id m = OF0x01.Message.marshal id m
  let to_string m = OF0x01.Message.to_string m
end

module Protocol = OFProtocol.Make(Message)
module ClientTable = Map.Make(Protocol.Client_id)

type h =
  | AwaitHello
  | AwaitFeatures

type s = OF0x01.SwitchFeatures.t
type c = Protocol.Client_id.t
type m = Message.t
type t = {
  protocol : Protocol.t;
  mutable switches : s ClientTable.t;
  mutable handshakes : h ClientTable.t
}

let init_handshake t (c_id : Protocol.Client_id.t)  =
  let open OpenFlow0x01.Message in
  Protocol.send t.protocol c_id (0l, Hello (Cstruct.of_string ""))
  >>= function
    | `Sent _ ->
      t.handshakes <- ClientTable.add t.handshakes c_id AwaitHello;
      return None
    | `Drop exn -> raise exn

let handshake t (c_id : Protocol.Client_id.t) (h : h) (msg : m) =
  let open OpenFlow0x01.Message in
  match h, msg with
    | AwaitHello, (_, Hello _) ->
      Protocol.send t.protocol c_id (0l, SwitchFeaturesRequest)
      >>= (function
        | `Sent _ ->
          t.handshakes <- ClientTable.add t.handshakes c_id AwaitFeatures;
          return None
        | `Drop exn ->
          t.handshakes <- ClientTable.remove t.handshakes c_id;
          raise exn)
    | AwaitFeatures, (_, SwitchFeaturesReply feats) ->
      t.switches <- ClientTable.add t.switches c_id feats;
      t.handshakes <- ClientTable.remove t.handshakes c_id;
      return (Some(`SwitchUp (c_id, feats)))
    | _, _ -> failwith "ERROR CASE" (* XXX(seliopou): handle this properly *)

let create port () =
  Protocol.create port (fun _ _ -> return `Allow) ()
  >>| fun p -> {
      protocol = p;
      switches = ClientTable.empty;
      handshakes = ClientTable.empty
    }

let listen (t : t) =
  let f (msg : Protocol.Server_read_result.t) =
    let open Protocol.Server_read_result in
    begin match msg with
      | Connect c_id -> init_handshake t c_id
      | Disconnect (c_id, _) ->
        t.switches <- ClientTable.remove t.switches c_id;
        return (Some(`SwitchDown c_id))
      | Denied_access msg -> failwith msg (* XXX(seliopu): handle this properly *)
      | Data (c_id, m) ->
        begin match ClientTable.find t.switches c_id with
          | Some _ -> return (Some(`Message (c_id, m)))
          | None ->
            begin match ClientTable.find t.handshakes c_id with
              | Some h -> handshake t c_id h m
              | None -> failwith "Should never happen (but should throw exn)"
            end
        end
    end in
  Pipe.filter_map' (Protocol.listen t.protocol) f

let close (t : t) (c : c) =
  Protocol.close t.protocol c;
  t.switches <- ClientTable.remove t.switches c

let has_switch (t : t) (c : c) =
  ClientTable.mem t.switches c

let flushed_time (t : t) (c : c) =
  match Protocol.flushed_time t.protocol c with
    | `Client_not_found -> `Switch_not_found
    | `Flushed d -> `Flushed d

let send (t : t) (c : c) (msg : m) =
  Protocol.send t.protocol c msg

let send_to_all (t : t) (msg : m) =
  Protocol.send_to_all t.protocol msg

let switch_addr_port (t : t) (c : c) =
  Protocol.client_addr_port t.protocol c
