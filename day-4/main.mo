import Account "account";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Array "mo:base/Array";

actor MotoCoin {

  type Account = Account.Account;

  let tokenName = "MotoCoin";
  let tokenSymbol = "MOC";
  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  public shared query func name() : async Text { tokenName };

  public shared query func symbol() : async Text { tokenSymbol };

  public shared query func totalSupply() : async Nat {
    var total = 0;
    for (amount in ledger.vals()) {
      total += amount;
    };
    return total;
  };

  public shared query func balanceOf(account : Account) : async (Nat) {
    switch(ledger.get(account)) {
      case(? amount) {
        return amount;
      };
      case(null) {
        return 0;
      };
    };
  };

  public shared func transfer(from: Account, to: Account, amount: Nat): async Result.Result<(), Text> {
    switch (ledger.get(from)) {
      case (? fromAmount) {
        if (fromAmount < amount) {
          return #err("Not enough coins in sender account.");
        };
        switch (ledger.get(to)) {
          case (?toAmount) {
            ledger.put(from, fromAmount - amount);
            ledger.put(to, toAmount + amount);
            return #ok;
          };
          case (null) {
            return #err("Target account not found.");
          };
        };  
      };
      case (null) {
        return #err("Sender account not found.");
      };
    };
  };

  public shared func airdrop() : async Result.Result<(), Text> {
    let studentsCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };

    let studentsList = await studentsCanister.getAllStudentsPrincipal();
    if (studentsList.size() == 0) {
      return #err("Bootcamp students not found.");
    };

    for (acc in ledger.keys()) {
      let principal = Array.find<Principal>(studentsList, func (x) { Account.accountBelongToPrincipal(acc, x)});
      if (principal != null) {
        switch(ledger.get(acc)) {
          case(? amount) {
            ledger.put(acc, amount + 100);
          };
          case(null) {};
        };
      };
    };
    return #ok;
  };

};