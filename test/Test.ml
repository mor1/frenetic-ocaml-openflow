open OpenFlow0x01
open OpenFlow0x01_Stats

module RoundTripping = struct
  TEST "OpenFlow Hello Test 1" = 
    let open Message in 
    let bs = Cstruct.create 101 in
    let m = Hello bs in 
    let x = 42l in 
    let s = marshal x m in  
    let h = Header.parse s in 
    let s' = String.sub s Header.size (Header.len h - Header.size) in 
    let x',m' = parse h s' in 
    let xid_ok = x = x' in 
    let msg_ok = 
      match m',m with 
	    | Hello bs', Hello bs ->
	      Cstruct.to_string bs = Cstruct.to_string bs'
	    | _ -> 
	      false in 
          xid_ok && msg_ok 
  
  TEST "OpenFlow Vendor Test 1" =
    let open Message in
    let bs = Cstruct.create 101 in
    let bs' = Cstruct.create ((Cstruct.len bs) + 4) in
    let body = "42 is the answer" in
    Cstruct.blit_from_string body 0 bs 0 (String.length body);
    let m = (42l, bs) in
    let _ = Vendor.marshal m bs' in
    let m' = Vendor.parse bs' in    
    match m, m' with
    | (42l, bs), (42l, bs') ->
      Cstruct.to_string bs = Cstruct.to_string bs'
    | _ ->
      false
  
  TEST "OpenFlow StatsReply DescriptionReply Test 1" =
    let open Message in
    let bs' = Cstruct.create 1060 in
    let content = {  
      manufacturer = String.create 256
      ; hardware = String.create 256
      ; software = String.create 256
      ; serial_number = String.create 32
      ; datapath = String.create 256} in
    let m = DescriptionRep content in
    let _ = StatsReply.marshal m bs' in
    let m' = StatsReply.parse bs' in
    match m, m' with
    | DescriptionRep rep, DescriptionRep rep' ->
      rep.manufacturer = rep'.manufacturer &&
      rep.hardware = rep'.hardware &&
      rep.serial_number = rep'.serial_number &&
      rep.datapath = rep'.datapath
    | _ -> 
      false
end