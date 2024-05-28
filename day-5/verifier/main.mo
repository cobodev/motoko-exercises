import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
actor Verifier {
  
  public type StudentProfile = {
    name : Text;
    Team : Text;
    graduate : Bool;
  };

  stable var entries : [(Principal, StudentProfile)] = [];
  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(5, Principal.equal, Principal.hash);

  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch(studentProfileStore.get(caller)) {
      case(null) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
      case(? something) {
        return #err("Profile already exists.")
      };
    };
  };

  public shared query func seeAProfile(p : Principal) : async ?StudentProfile {
    return studentProfileStore.get(p);
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch(studentProfileStore.get(caller)) {
      case(?p) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
      case(null) {
        return #err("Profile not found.")
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch(studentProfileStore.get(caller)) {
      case(?p) {
        studentProfileStore.delete(caller);
        return #ok;
      };
      case(null) {
        return #err("Profile not found.")
      };
    };
  };

  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    entries := [];
  };

}