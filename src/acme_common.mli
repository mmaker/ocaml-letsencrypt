val letsencrypt_production_url : Uri.t

val letsencrypt_staging_url : Uri.t

val sha256_and_base64 : string -> string

type json = Yojson.Safe.t

val json_to_string : ?comma:string -> ?colon:string -> json -> string

module Jwk : sig
  (** [Jwk]: Json Web Key.

      Jwk is an implementation of the Json Web Key standard (RFC7638).
  *)

  (** [key] identifies a key. *)
  type 'a key = 'a Jose.Jwk.t

  val thumbprint : 'a key -> string
  (** [thumbprint key] produces the JWK thumbprint of [key]. *)

  val encode : 'a key -> json

  val decode : string -> (Jose.Jwk.public key, 
  [>  `Json_parse_failed of string
    | `Msg of string
    | `Unsupported_kty ]) result
end

module Jws : sig
  (** [Jws]: Json Web Signatures.

      Jws is an implementation of the Json Web Signature Standard (RFC7515).
      Currently, encoding and decoding operations only support the RS256
      algorithm; specifically the encoding operation is a bit rusty, and probably
      its interface will change in the future.  *)

  (** type [header] records information about the header. *)
  type header = Jose.Header.t

  val encode_acme : ?kid_url:Uri.t -> data:string -> ?nonce:string -> Uri.t ->
    Jose.Jwk.priv Jose.Jwk.t -> string

  val encode : ?protected:(string * json) list -> data:string ->
    ?nonce:string -> Jose.Jwk.priv Jose.Jwk.t -> string

  val decode : ?pub:(Jose.Jwk.public Jose.Jwk.t) -> string ->
    (header * string, [> `Invalid_signature | `Msg of string | `Not_json | `Not_supported ]) result
end

module Directory : sig
  (** ACME json data types, as defined in RFC 8555 *)

  type meta = {
    terms_of_service : Uri.t option;
    website : Uri.t option;
    caa_identities : string list option;
  }

  val pp_meta : meta Fmt.t

  type t = {
    new_nonce : Uri.t;
    new_account : Uri.t;
    new_order : Uri.t;
    new_authz : Uri.t option;
    revoke_cert : Uri.t;
    key_change : Uri.t;
    meta : meta option;
  }

  val pp : t Fmt.t

  val decode : string -> (t, [> `Msg of string ]) result
end

module Account : sig
  type t = {
    account_status : [ `Valid | `Deactivated | `Revoked ];
    contact : string list option;
    terms_of_service_agreed : bool option;
    orders : Uri.t option;
    initial_ip : string option;
    created_at : Ptime.t option;
  }

  val pp : t Fmt.t

  val decode : string -> (t, [> `Msg of string ]) result
end

type id_type = [ `Dns ]

module Order : sig
  type t = {
    order_status : [ `Pending | `Ready | `Processing | `Valid | `Invalid ];
    expires : Ptime.t option;
    identifiers : (id_type * string) list;
    not_before : Ptime.t option;
    not_after : Ptime.t option;
    error : json option;
    authorizations : Uri.t list;
    finalize : Uri.t;
    certificate : Uri.t option;
  }

  val pp : t Fmt.t

  val decode : string -> (t, [> `Msg of string ]) result
end

module Challenge : sig
  type typ = [ `Dns | `Http | `Alpn ]

  val pp_typ : typ Fmt.t

  type t = {
    challenge_typ : typ;
    url : Uri.t;
    challenge_status : [ `Pending | `Processing | `Valid | `Invalid ];
    token : string;
    validated : Ptime.t option;
    error : json option;
  }

  val pp : t Fmt.t
end

module Authorization : sig
  type t = {
    identifier : id_type * string;
    authorization_status : [ `Pending | `Valid | `Invalid | `Deactivated | `Expired | `Revoked ];
    expires : Ptime.t option;
    challenges : Challenge.t list;
    wildcard : bool;
  }

  val pp : t Fmt.t

  val decode : string -> (t, [> `Msg of string ]) result
end

module Error : sig
  type t = {
    err_typ : [
      | `Account_does_not_exist | `Already_revoked | `Bad_csr | `Bad_nonce
      | `Bad_public_key | `Bad_revocation_reason | `Bad_signature_algorithm
      | `CAA | `Connection | `DNS | `External_account_required
      | `Incorrect_response | `Invalid_contact | `Malformed | `Order_not_ready
      | `Rate_limited | `Rejected_identifier | `Server_internal | `TLS
      | `Unauthorized | `Unsupported_contact | `Unsupported_identifier
      | `User_action_required
    ];
    detail : string
  }

  val pp : t Fmt.t

  val decode : string -> (t, [> `Msg of string ]) result
end
