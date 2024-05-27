import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";

actor HomeworkDiary {
  type Homework = {
    title : Text;
    description : Text;
    dueDate : Time.Time;
    completed : Bool;
  };

  let homeworkDiary = Buffer.Buffer<Homework>(0);

  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return homeworkDiary.size();
  };

  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    switch(homeworkDiary.getOpt(id)) {
      case(null){
        return #err("Homework not found.");
      };
      case(? task){
        return #ok(task);
      };
    };
  };

  public shared func updateHomework(id: Nat, homework: Homework) : async Result.Result<(), Text> {
    switch(homeworkDiary.getOpt(id)) {
      case(null){
        return #err("Homework not found.");
      };
      case(? task){
        homeworkDiary.put(id, homework);
        return #ok;
      };
    };
  };

  public shared func markAsCompleted(id: Nat) : async Result.Result<(), Text> {
    switch(homeworkDiary.getOpt(id)) {
      case(null){
        return #err("Homework not found.");
      };
      case(? task){
        let updatedTask = { 
          title = task.title; 
          description = task.description; 
          dueDate = task.dueDate; 
          completed = true 
        };
        homeworkDiary.put(id, updatedTask);
        return #ok;
      };
    };
  };

  public shared func deleteHomework(id: Nat) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      return #err("Homework not found.");
    } else {
      let task = homeworkDiary.remove(id);
      return #ok;
    }
  };

  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray<Homework>(homeworkDiary);
  };

  public shared query func getPendingHomework() : async [Homework] {
    return Array.filter<Homework>(Buffer.toArray<Homework>(homeworkDiary), func (task: Homework) : Bool {
      not task.completed
    });
  };

  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    return Array.filter<Homework>(Buffer.toArray<Homework>(homeworkDiary), func (task: Homework) : Bool {
      Text.contains(task.title, #text searchTerm) or Text.contains(task.description, #text searchTerm)
    });
  };
};