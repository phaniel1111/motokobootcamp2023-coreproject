import T "mo:base/Text";
import O "mo:base/Option";
import A "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import CertifiedData "mo:base/CertifiedData";
import SHA256 "SHA256";
import Text "mo:base/Text";
//import SHA256 "mo:sha256/SHA256"

actor Self {
  stable var last_message : Text = "Nobody said anything yet.";

  let daocanister: Principal = Principal.fromText("no4gy-cqaaa-aaaag-abc4q-cai");

  public shared({caller}) func leave_message(msg : Text) : async () {
    if(caller == daocanister){
      last_message := msg;
      update_asset_hash(); // will be explained below
    }
  };

  func my_id(): Principal = Principal.fromActor(Self);

  func main_page(): Blob {
    return T.encodeUtf8 (
      last_message
    )
  };

  type HeaderField = (Text, Text);

  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
  };

  type HttpRequest  = {
    method: Text;
    url: Text;
    headers: [HeaderField];
    body: Blob;
  };

  public query func http_request(req : HttpRequest) : async HttpResponse {
    // check if / is requested
    if ((req.method, req.url) == ("GET", "/")) {
      // If so, return the main page with with right headers
      return {
        status_code = 200;
        headers = [ ("content-type", "text/plain"), certification_header() ];
        body = main_page()
      }
    } else {
      // Else return an error code. Note that we cannot certify this response
      // so a user going to https://ce7vw-haaaa-aaaai-aanva-cai.ic0.app/foo
      // will not see the error message
      return {
        status_code = 404;
        headers = [ ("content-type", "text/plain") ];
        body = Text.encodeUtf8(last_message);
      }
    }
  };

  type Hash = Blob;
  type Key = Blob;
  type Value = Blob;
  type HashTree = {
    #empty;
    #pruned : Hash;
    #fork : (HashTree, HashTree);
    #labeled : (Key, HashTree);
    #leaf : Value;
  };

  func asset_tree() : HashTree {
    #labeled ("http_assets",
      #labeled ("/",
        #leaf (h(main_page()))
      )
    );
  };

  func update_asset_hash() {
    CertifiedData.set(hash_tree(asset_tree()));
  };

  system func postupgrade() {
    update_asset_hash();
  };

  func certification_header() : HeaderField {
    let cert = switch (CertifiedData.getCertificate()) {
      case (?c) c;
      case null {
        // unfortunately, we cannot do
        //   throw Error.reject("getCertificate failed. Call this as a query call!")
        // here, because this function isn’t async, but we can’t make it async
        // because it is called from a query (and it would do the wrong thing) :-(
        //
        // So just return erronous data instead
        "getCertificate failed. Call this as a query call!" : Blob
      }
    };
    return
      ("ic-certificate",
        "certificate=:" # base64(cert) # ":, " #
        "tree=:" # base64(cbor_tree(asset_tree())) # ":"
      )
  };

  func h(b1 : Blob) : Blob {
    let d = SHA256.Digest();
    d.write(Blob.toArray(b1));
    Blob.fromArray(d.sum());
  };
  func h2(b1 : Blob, b2 : Blob) : Blob {
    let d = SHA256.Digest();
    d.write(Blob.toArray(b1));
    d.write(Blob.toArray(b2));
    Blob.fromArray(d.sum());
  };
  func h3(b1 : Blob, b2 : Blob, b3 : Blob) : Blob {
    let d = SHA256.Digest();
    d.write(Blob.toArray(b1));
    d.write(Blob.toArray(b2));
    d.write(Blob.toArray(b3));
    Blob.fromArray(d.sum());
  };

  func base64(b : Blob) : Text {
    let base64_chars : [Text] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"];
    let bytes = Blob.toArray(b);
    let pad_len = if (bytes.size() % 3 == 0) { 0 } else {3 - bytes.size() % 3 : Nat};
    let padded_bytes = A.append(bytes, A.tabulate<Nat8>(pad_len, func(_) { 0 }));
    var out = "";
    for (j in Iter.range(1,padded_bytes.size() / 3)) {
      let i = j - 1 : Nat; // annoying inclusive upper bound in Iter.range
      let b1 = padded_bytes[3*i];
      let b2 = padded_bytes[3*i+1];
      let b3 = padded_bytes[3*i+2];
      let c1 = (b1 >> 2          ) & 63;
      let c2 = (b1 << 4 | b2 >> 4) & 63;
      let c3 = (b2 << 2 | b3 >> 6) & 63;
      let c4 = (b3               ) & 63;
      out #= base64_chars[Nat8.toNat(c1)]
          # base64_chars[Nat8.toNat(c2)]
          # (if (3*i+1 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c3)] })
          # (if (3*i+2 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c4)] });
    };
    return out
  };

  func hash_tree(t : HashTree) : Hash {
    switch (t) {
      case (#empty) {
        h("\11ic-hashtree-empty");
      };
      case (#fork(t1,t2)) {
        h3("\10ic-hashtree-fork", hash_tree(t1), hash_tree(t2));
      };
      case (#labeled(l,t)) {
        h3("\13ic-hashtree-labeled", l, hash_tree(t));
      };
      case (#leaf(v)) {
        h2("\10ic-hashtree-leaf", v)
      };
      case (#pruned(h)) {
        h
      }
    }
  };

  func cbor_tree(tree : HashTree) : Blob {
    let buf = Buffer.Buffer<Nat8>(100);

    // CBOR self-describing tag
    buf.add(0xD9);
    buf.add(0xD9);
    buf.add(0xF7);

    func add_blob(b: Blob) {
      // Only works for blobs with less than 256 bytes
      buf.add(0x58);
      buf.add(Nat8.fromNat(b.size()));
      for (c in Blob.toArray(b).vals()) {
        buf.add(c);
      };
    };

    func go(t : HashTree) {
      switch (t) {
        case (#empty)        { buf.add(0x81); buf.add(0x00); };
        case (#fork(t1,t2))  { buf.add(0x83); buf.add(0x01); go(t1); go (t2); };
        case (#labeled(l,t)) { buf.add(0x83); buf.add(0x02); add_blob(l); go (t); };
        case (#leaf(v))      { buf.add(0x82); buf.add(0x03); add_blob(v); };
        case (#pruned(h))    { buf.add(0x82); buf.add(0x04); add_blob(h); }
      }
    };

    go(tree);

    return Blob.fromArray(buf.toArray());
  };
};