import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import List "mo:base/List";
import Principal "mo:base/Principal";

module {
  public type Result<T, E> = Result.Result<T, E>;
  public type Proposal = {
    id : Nat;
    votes_no : Tokens;
    voters : List.List<Principal>;
    state : ProposalState;
    timestamp : Int;
    proposer : Principal;
    votes_yes : Tokens;
    payload : Text;
    method: Method;
    limit_to_vote: Nat;
    proposal_vote_threshold: Nat;
  };

  public type ProposalState = {
      // A failure occurred while executing the proposal
      #failed : Text;
      // The proposal is open for voting
      #open;
      // The proposal is currently being executed
      #executing;
      // Enough "no" votes have been cast to reject the proposal, and it will not be executed
      #rejected;
      // The proposal has been successfully executed
      #succeeded;
      // Enough "yes" votes have been cast to accept the proposal, and it will soon be executed
      #accepted;
  };
  public type Tokens = { amount_e8s : Int };
  public type Vote = { #no; #yes };
  public type Method = { #general; #quadratic };
  public type VoteArgs = { vote : Vote; proposal_id : Nat };
  public type VoteRequire = { method: Method ; limit_to_vote: ?Nat; proposal_vote_threshold: ?Nat};
  public let oneToken = { amount_e8s = 100_000_000 };
  public let zeroToken = { amount_e8s = 0 };  

  public func proposal_key(t: Nat) : Trie.Key<Nat> = { key = t; hash = Int.hash t };
}