import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import ic "ic";

actor Verifier {

  /* TYPES */
  public type StudentProfile = {
    name : Text;
    Team : Text;
    graduate : Bool;
  };
  public type TestResult = Result.Result<(), TestError>;
  public type TestError = {
    #UnexpectedValue : Text;
    #UnexpectedError : Text;
  };
  public type ManagementCanister = ic.ManagementCanister;

  /* VARS */
  private var studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(5, Principal.equal, Principal.hash);
  private stable var entries : [(Principal, StudentProfile)] = [];

  /* HELPER */
  public shared query ({ caller }) func whoami() : async Principal { caller };

  /* STUDENTS INFORMATION */
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
      case (?something) {
        return #err("Profile already exists!");
      };
    };
  };

  public shared query func seeAProfile(p : Principal) : async ?StudentProfile {
    return studentProfileStore.get(p);
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (?p) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
      case (null) {
        return #err("Profile not found.");
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (?p) {
        studentProfileStore.delete(caller);
        return #ok;
      };
      case (null) {
        return #err("Profile not found.");
      };
    };
  };

  /* TESTING CANISTER */
  public shared func test(canisterId : Principal) : async TestResult {
    let calculator = actor (Principal.toText(canisterId)) : actor {
      add : shared (n : Int) -> async Int;
      sub : shared (n : Nat) -> async Int;
      reset : shared () -> async Int;
    };

    try {
      // Reset test
      var result = await calculator.reset();
      if (result != 0) {
        return #err(#UnexpectedValue "Test failed in reset function.");
      };
      // Add test
      result := await calculator.add(10);
      if (result != 10) {
        return #err(#UnexpectedValue "Test failed in add function.");
      };
      // Sub test
      result := await calculator.sub(5);
      if (result != 5) {
        return #err(#UnexpectedValue "Test failed in sub function.");
      };
    } catch (e) {
      return #err(#UnexpectedError "Unexpected error calling canister.");
    };

    return #ok;
  };

  /* TESTING OWNERSHIP */
  func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };
  
  public shared func verifyOwnership(canisterId : Principal, principalId : Principal) : async Bool {
    let calculator : ManagementCanister = actor (Principal.toText(canisterId));
    try {
      let status = await calculator.canister_status({ canister_id = canisterId });
      return false;
    } catch (e) {
      let controllers = parseControllersFromCanisterStatusErrorIfCallerNotController(Error.message(e));
      let findPrincipal = Array.find<Principal>(controllers, func (x) { Principal.toText(x) == Principal.toText(principalId) });
      return findPrincipal != null;
    };
    
  };

  /* VERIFYING WORK */
  public shared func verifyWork(canisterId: Principal, principalId: Principal) : async Result.Result<(), Text> {
    let isOwner = await verifyOwnership(canisterId, principalId);
    if (not isOwner) {
      return #err("You must be the controller of the canister.");
    };
    let testPassed = await test(canisterId);
    if (testPassed != #ok) {
      return #err("Tests not passed.")
    };

    switch (studentProfileStore.get(principalId)) {
      case (?p) {
        studentProfileStore.put(principalId, {
          name = p.name;
          Team = p.Team;
          graduate = true;
        });
        return #ok;
      };
      case (null) {
        return #err("Profile not found.");
      };
    };
  };

  /* PREUPGRADE AND POSTUPGRADE */
  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    studentProfileStore := HashMap.fromIter<Principal, StudentProfile>(entries.vals(), 5, Principal.equal, Principal.hash);
    entries := [];
  };

};
