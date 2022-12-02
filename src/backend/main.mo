//  ----------- Decription
//  This Motoko file contains the logic of the backend canister.

//  ----------- Imports

//  Imports from Motoko Base Library
import Array        "mo:base/Array";
import Bool         "mo:base/Bool";
import Blob         "mo:base/Blob";
import Buffer       "mo:base/Buffer";
import Hash         "mo:base/Hash";
import Int          "mo:base/Int";
import Iter         "mo:base/Iter";
import Nat          "mo:base/Nat";
import Nat32        "mo:base/Nat32";
import Nat64        "mo:base/Nat64";
import Option       "mo:base/Option";
import Principal    "mo:base/Principal";
import Text         "mo:base/Text";
import Time         "mo:base/Time";
import TrieMap      "mo:base/TrieMap";

//  Imports from helpers, utils, & types
import Account      "lib/Account";
import AES          "lib/AES";
import Hex          "lib/Hex";
import T            "types";
import Helpers      "helpers";

//  Imports from external interfaces
import LT           "../ledger/ledger";
import NT           "../ntagle/ntagle";

shared actor class SDM() = this {

  //  ----------- Variables
  private stable var tag_total : Nat = 0;
  private stable var chat_messages : Nat = 0;
  let internet_identity_principal_isaac : Principal = Principal.fromText("gvi7s-tbk2k-4qba4-mw6qj-azomr-rrwex-byyqb-icyrn-eygs4-nrmm5-eae");
  var admins : [Principal] = [internet_identity_principal_isaac]; 

  //  ----------- State
  private stable var ownersEntries : [(T.TagUid, Principal)] = [];
  private stable var balancesEntries : [(Principal, [T.TagUid])] = [];
  private stable var tagWalletsEntries : [(T.TagUid, Account.AccountIdentifier)] = [];
  private stable var chatsEntries : [(Nat, T.ChatMessage)] = [];

  private let owners : TrieMap.TrieMap<T.TagUid, Principal> = TrieMap.fromEntries<T.TagUid, Principal>(ownersEntries.vals(), Text.equal, Text.hash);
  private let balances : TrieMap.TrieMap<Principal, [T.TagUid]> = TrieMap.fromEntries<Principal, [T.TagUid]>(balancesEntries.vals(), Principal.equal, Principal.hash);
  private let tagWallets : TrieMap.TrieMap<T.TagUid, Account.AccountIdentifier> = TrieMap.fromEntries<T.TagUid, Account.AccountIdentifier>(tagWalletsEntries.vals(), Text.equal, Text.hash);
  private let chats : TrieMap.TrieMap<Nat, T.ChatMessage> = TrieMap.fromEntries<Nat, T.ChatMessage>(chatsEntries.vals(), Nat.equal, Hash.hash);

  //  ----------- Configure external actors
  let Ledger = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : LT.Self;
  let icp_fee : Nat64 = 10_000;

  let Ntagle = actor "gq4xa-gqaaa-aaaal-abmta-cai" : NT.SDM;
  let my_profile = {
    url = "https://erfdz-cyaaa-aaaal-abm6q-cai.ic0.app/";
    name = "Tradeable HW Wallet";
    description = "Binds an ICP wallet to the tag.";
    image = "https://erfdz-cyaaa-aaaal-abm6q-cai.ic0.app/favicon.svg";
  };

  //  ----------- Public functions
  public shared({ caller }) func initializeNtagle() {
    //  assert(_isAdmin(caller));
    
    Ntagle.registerIntegrator(my_profile);
  };

  public shared({ caller }) func whoami() : async Principal {
    return caller;
  };

  public query func getRegistry() : async [(T.TagUid, Principal)] {
    _getOwnerEntries();
  };

  public shared({ caller }) func isAdmin() : async Bool {
    if (_isAdmin(caller)) {
      return true;
    };
    return false;
  };

  public shared({ caller }) func validateAccess(request : T.ValidationRequest) : async T.ValidationResult {
    let full_request : NT.ValidationRequest = {
      user = caller;
      validation = request.validation;
      access_code = request.access_code;
    };
      let sdm_result = await Ntagle.validateAccess(full_request);

      _validate(caller, sdm_result);
  };

  public shared({ caller }) func tagBalance(uid : T.TagUid) : async Nat64 {
    await _tagBalance(uid);
  };

  public shared({ caller }) func withdraw(
      uid : T.TagUid, 
      account_id : [Nat8], 
      amount : Nat64
    ) : async LT.TransferResult {
      assert(_isOwner(uid, caller));

      await _withdraw(
        uid, 
        account_id,
        amount
      ); 
  };

  public shared({ caller }) func postMessage(message : T.NewMessage) : async [T.LoggedMessage] {
    assert _isOwner(message.uid, caller);

    chat_messages += 1;
    await _postMessage(caller, message);
  };

  public shared({ caller }) func getChatLog(
    uid : T.TagUid, 
    location: ?T.Location
    ) : async [T.LoggedMessage] {
      assert _isOwner(uid, caller);

      _chatLog(location);
  };

  //  ----------- Directly called private functions
  private func _getOwnerEntries() : [(T.TagUid, Principal)] {
    Iter.toArray(owners.entries());
  };

  private func _isAdmin (p: Principal) : Bool {
    return(Helpers.contains<Principal>(admins, p, Principal.equal))
  };

  private func _validate(
    caller : Principal, 
    sdm_result : NT.ValidationResult
    ) : T.ValidationResult {

      switch (sdm_result) {
        case (#Ok(validationResponse)) {

          switch (tagWallets.get(validationResponse.tag)) {
            case (?wallet) {

              //  Handle Existing Wallet
              switch (owners.get(validationResponse.tag)) {
                case (?owner) {
                  
                  //  Handle return success (wallet already existed)

                  //  Handle if they are claiming ownership
                  if (owner != caller) {
                    _removeTagFromBalance(owner, validationResponse.tag);
                    _addTagToBalance(caller, validationResponse.tag);
                    owners.put(validationResponse.tag, caller);
                  };

                  let result = {
                    tag = validationResponse.tag;
                    owner = true;
                    wallet = wallet;
                  };

                  return #Ok(result);
                };

                case _ {
                  return #Err({
                    msg = "Something is wrong. Found the wallet but not the owner.";
                  });
                };
              };
            };

            case _ {

              //  Handle Create New Wallet
              let tag_wallet : Account.AccountIdentifier = Helpers.getUidWallet(Principal.fromActor(this), validationResponse.tag);

              if (not Option.isSome(owners.get(validationResponse.tag))) {
                owners.put(validationResponse.tag, caller);
              };
              _addTagToBalance(caller, validationResponse.tag);
              tagWallets.put(validationResponse.tag, tag_wallet);

              let result = {
                tag = validationResponse.tag;
                owner = true;
                wallet = tag_wallet;
              };

              return #Ok(result);
            };
          };
        };

        case (#Err(#ValidationNotFound)) {
          return #Err({
            msg = "Validation not found";
          });
        };

        case (#Err(#IntegrationNotFound)) {
          return #Err({
            msg = "Integration not found";
          });
        };

        case (#Err(#NotAuthorized)) {
          return #Err({
            msg = "This canister was not authorized";
          });
        };

        case (#Err(#TagNotFound)) {
          return #Err({
            msg = "Tag not found";
          });
        };

        case (#Err(#Invalid)) {
          return #Err({
            msg = "Access code not valid";
          });
        };

        case (#Err(#Expired)) {
          return #Err({
            msg = "Access code expired (it's longer than 10 minutes old)";
          });
        };
      };
  };

  private func _tagBalance(uid : T.TagUid) : async Nat64 {

    switch (tagWallets.get(uid)) {
      case (?wallet) {
        let icpBalance = await Ledger.account_balance({
          account = Blob.toArray(wallet);
        });

        return icpBalance.e8s;
      };

      case _ {
        return 0 : Nat64;
      }
    };
  };

  private func _isOwner(
    uid : T.TagUid, 
    p : Principal
    ) : Bool {

      switch (owners.get(uid)) {
        case (?v) {
          return v == p;
        };

        case _ {
          return false;
        };
      };
  };

  //  At some point add a tag info check
  private func _withdraw(
    uid : T.TagUid,
    account_id : [Nat8],
    amount : Nat64
    ) : async LT.TransferResult {
      var icp_amount = 0 :Nat64;

      if (amount == 0) {
        icp_amount := await _tagBalance(uid);
      } else {
        icp_amount := amount;
      };

      //  Transfer that amount back to user
      await transferICP(
        uid, 
        account_id, 
        icp_amount
      );
  };

  private func _postMessage(
    caller : Principal, 
    message : T.NewMessage
    ) : async [T.LoggedMessage] {
      let new_message : T.ChatMessage = {
        from = caller;
        uid = message.uid;
        time = Nat64.fromNat(Int.abs(Time.now()));
        balance = await _tagBalance(message.uid);
        location = message.location;
        message = message.message;
      };

      chats.put(chat_messages, new_message);

      return _chatLog(message.location);
  };

  //  ----------- Additional private functions
  private func _addTagToBalance(
    p : Principal, 
    uid : T.TagUid
    ) {
      switch (balances.get(p)) {
        case (?v) {
          balances.put(p, Array.append(v,[uid]));
        };
        case null {
          balances.put(p, [uid]);
        }
      }
  };

  private func _removeTagFromBalance(
    p : Principal, 
    uid : T.TagUid
    ) {
      switch (balances.get(p)) {
        case (?v) {
          balances.put(p, Array.filter<T.TagUid>(v, func (e : T.TagUid) : Bool { e != uid; }));
        };
        case null {
          balances.put(p, [uid]);
        }
      }
  };

  private func _tag_exists(uid : T.TagUid) : Bool {
    return Option.isSome(owners.get(uid));
  };

  private func _chatLog(location : ?T.Location) : [T.LoggedMessage] {
    let result = Buffer.Buffer<T.LoggedMessage>(chat_messages);

    for (message in chats.vals()) {
      result.add({
        from = message.from;
        uid = message.uid;
        time = message.time;
        balance = message.balance;
        location = Helpers.distance(location, message.location);
        message = message.message
      });
    };

    return result.toArray();    
  };

  //  ----------- ICP Ledger & Transaction Functions
  private func transferICP(
    uid : T.TagUid, 
    transferTo : [Nat8], 
    transferAmount : Nat64
    ) : async LT.TransferResult {
      let res =  await Ledger.transfer({
        memo: Nat64 = 0;
        from_subaccount = ?Blob.toArray(Helpers.uidToSubaccount(uid));
        to = transferTo;
        //  The amount of ICP, minus the necessary transaction fee
        amount = { e8s = transferAmount - icp_fee };
        fee = { e8s = icp_fee };
        created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
      });
  };


  //  ----------- System functions
  system func preupgrade() {
    ownersEntries := Iter.toArray(owners.entries());
    balancesEntries := Iter.toArray(balances.entries());
    tagWalletsEntries := Iter.toArray(tagWallets.entries());
    chatsEntries := Iter.toArray(chats.entries());
  };

  system func postupgrade() {
    ownersEntries := [];
    balancesEntries := [];
    tagWalletsEntries := [];
    chatsEntries := [];
  };
};