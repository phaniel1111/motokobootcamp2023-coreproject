import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import List "mo:base/List";
import Principal "mo:base/Principal";

module {
  public type Result<T, E> = Result.Result<T, E>;
  public type Neuron = {
    id: Nat;
    owner : Principal;
    amount: Nat;
    state : NeuronState;
    age: Int;
    timecreate : Int;
    delaytime: Int;
    lastaccess: Int;
  };

  public type NeuronState = {
    #locked;
    #dissolving;
    #dissolved;
  };

  public func neuron_key(t: Nat) : Trie.Key<Nat> = { key = t; hash = Int.hash t };
  
}