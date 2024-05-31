import Result "mo:base/Result";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Array "mo:base/Array";

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

  public shared ({ caller }) func updateMessage(messageId : Nat, c: Content) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(? message) {
        if (caller == message.creator) {
          wall.put(messageId, {
            vote = message.vote;
            content = c;
            creator = message.creator;
          });
          return #ok;
        } else {
          return #err("You are not the creator.")
        };
      };
      case(null) {
        return #err("Message not found.")
      };
    };
  };

  public shared func deleteMessage(messageId: Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(? message) {
        wall.delete(messageId);
        return #ok;
      };
      case(null) {
        return #err("Message not found.");
      };
    };
  };

  public shared func upVote(messageId: Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(? message) {
        wall.put(messageId, {
          vote = message.vote + 1;
          content = message.content;
          creator = message.creator;
        });
        return #ok;
      };
      case(null) {
        return #err("Message not found.")
      };
    };
  };

  public shared func downVote(messageId: Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(? message) {
        wall.put(messageId, {
          vote = message.vote - 1;
          content = message.content;
          creator = message.creator;
        });
        return #ok;
      };
      case(null) {
        return #err("Message not found.")
      };
    };
  };

  public shared query func getAllMessages() : async [Message] {
    return Iter.toArray(wall.vals());
  };

  public shared query func getAllMessagesRanked() : async [Message] {
    let values = Iter.toArray(wall.vals());
    return Array.reverse(
      Array.sort<Message>(values, func (a, b) {
        return Int.compare(a.vote, b.vote);
      })
    );
  };
};