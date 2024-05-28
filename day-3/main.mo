import Result "mo:base/Result";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

actor StudentWall {

  public type Content = {
    #Text: Text;
    #Image: Blob;
    #Video: Blob;
  };

  type Message = {
    vote : Int;
    content : Content;
    creator : Principal;
  };

  var messageId : Nat = 0;
  let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, Hash.hash);

  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let message = {
      vote = 0;
      content = c;
      creator = caller;
    };
    messageId += 1;
    wall.put(messageId, message);
    return messageId;
  };

  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    switch(wall.get(messageId)) {
      case(? message) {
        return #ok(message);
      };
      case(null) {
        return #err("Message not found.");
      };
    };
  };

  public shared func updateMessage(messageId : Nat, c: Content) : async Result.Result<(), Text> {
    // asd
  };

  public shared func deleteMessage(messageId: Nat) : async Result.Result<(), Text> {
    // asd
  };

  public shared func upVote(messageId: Nat) : async Result.Result<(), Text> {
    // asd
  };

  public shared func downVote(messageId: Nat) : async Result.Result<(), Text> {
    // asd
  };

  public shared query func getAllMessages() : async [Message] {
    // asd
  };

  public shared query func getAllMessagesRanked() : async [Message] {
    // asd
  };
};