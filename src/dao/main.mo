import Token "./Token";
import Types "./Types";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Error "mo:base/Error";
import ICRaw "mo:base/ExperimentalInternetComputer";
import List "mo:base/List";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
//import Webpage "canister:webpage";
import DAONeuron "./Neuron";
actor{

    stable var next_proposal_id : Nat = 0;
    stable var proposals = Trie.empty<Nat, Types.Proposal>();
    let token = actor("db3eq-6iaaa-aaaah-abz6a-cai"): Token.Self;
    let Webpage : actor { leave_message : (Text) -> () } = actor ("wuxdo-mqaaa-aaaam-qauoa-cai"); 
    //public shared({caller}) func getinfo(pid: service.Account__1) : async service.Balance__1{
    //    await service.icrc1_balance_of(pid);
   // };
    stable var neurons = Trie.empty<Nat, DAONeuron.Neuron>();
    stable var next_neuron_id : Nat = 0;

    let daocanister: Principal = Principal.fromText("no4gy-cqaaa-aaaag-abc4q-cai");
    let anonymous: Principal = Principal.fromText("2vxsx-fae");
    let kietpid: Principal = Principal.fromText("4jh3v-f4lyo-nisot-t665v-zxrmu-um567-h6wpv-72agt-arudk-vzp6u-tae");

    public query func getCanisterid(): async Principal{
        return daocanister;
    };
    func neuron_put(id : Nat, neuron : DAONeuron.Neuron) {
        neurons := Trie.put(neurons, DAONeuron.neuron_key(id), Nat.equal, neuron).0;
    };
    func neuron_get(id : Nat) : ?DAONeuron.Neuron = Trie.get(neurons, DAONeuron.neuron_key(id), Nat.equal);

    public shared({caller}) func create_neuron(rs: Token.Result, dl: Int) : async DAONeuron.Result<Nat, Text> {
        let neuron_id = next_neuron_id;
        next_neuron_id += 1;
        var strID : Token.TxIndex__1 = 0;
        switch (rs) {
          case (#ok(n)) strID := n;
          case (#err(text)) return #err("Can't create neuron");
        };
        var tax : ?Token.Transaction__1 = null;
        var temp : Token.Balance = 0;
        switch (await token.get_transaction(strID)){
          case (null) return #err("Can't create neuron");
          case (?t) {
            tax := ?t;
            switch (t.transfer){
              case (null) return #err("Can't create neuron");
              case (?t1) temp := t1.amount;
            };
            switch (t.transfer){
              case (null) return #err("Can't create neuron");
              case (?t1) {  
                if(t1.from.owner != caller or t1.to.owner != daocanister) //change kiet to caller
                  return #err("Can't create neuron");
                temp := t1.amount;
              };
            };
          };
        };
        let n : DAONeuron.Neuron = {
            id = neuron_id;
            owner = caller;
            amount= temp;
            state = #locked;
            age= 0;
            timecreate = Time.now();
            lastaccess = Time.now();
            delaytime= dl;
        };
        neuron_put(neuron_id, n);
        return #ok(neuron_id);
    };

    public shared({caller}) func update_neuron(neuron_id: Nat) : async ?DAONeuron.Neuron {
      let n = neuron_get(neuron_id);
      switch(n){
        case (null) return null;
        case (?n1){
            if(n1.state == #dissolved) return ?n1;
            if(n1.state == #locked){
                let n2 : DAONeuron.Neuron = {
                    id = n1.id;
                    owner = n1.owner;
                    amount= n1.amount;
                    state = n1.state;
                    age= n1.age + (Time.now() - n1.lastaccess);
                    timecreate = n1.timecreate;
                    lastaccess = Time.now();
                    delaytime= n1.delaytime;
                };
                neuron_put(n1.id, n2);
                return ?n2;
            };
            if(n1.state == #dissolving){
                let temp = Time.now() - n1.lastaccess;
                var delay : Int = 0;
                var state : DAONeuron.NeuronState = #dissolved;
                var age1 : Int = n1.age + n1.delaytime;
                if(n1.delaytime > temp){
                    delay := n1.delaytime - temp;
                    state := #dissolving;
                    age1 := n1.age + temp;
                };

                let n2 : DAONeuron.Neuron = {
                    id = n1.id;
                    owner = n1.owner;
                    amount= n1.amount;
                    state = state;
                    age = age1;
                    timecreate = n1.timecreate;
                    lastaccess = Time.now();
                    delaytime = delay;
                };
                neuron_put(n1.id, n2);
                return ?n2;
            };
            return ?n1;
        }
      }
    };
    public shared({caller}) func dissolveNeuron(neuron_id: Nat) : async DAONeuron.Result<Nat, Text> {
      let n = neuron_get(neuron_id);
      
      switch(n){
        case (null) return #err("Neuron doesn't exist");
        case (?n1){
            if(caller != n1.owner) return #err("You are not the owner");
            if(n1.state == #dissolving) return #err("Neuron is dissolving");
            if(n1.state == #dissolved) return #err("Neuron was dissolved");
            if(n1.state == #locked){
                let n2 : DAONeuron.Neuron = {
                    id = n1.id;
                    owner = n1.owner;
                    amount= n1.amount;
                    state = #dissolving;
                    age= n1.age;
                    timecreate = n1.timecreate;
                    lastaccess = n1.lastaccess;
                    delaytime= n1.delaytime;
                };
                neuron_put(n1.id, n2);
                return #ok(n1.id);
            };
            return #ok(n1.id);
        };
        
      };
    };

    func ageBonus(age: Int) : Float{
        return 1+ (Float.fromInt(age)/5049216001000000000);
    };
    func delayBonus(delay: Int) : Float{
        return (1.06 + 0.94* Float.fromInt(delay)/252460800000000000);
    };
    public shared({caller}) func votingPower(neuron_id: Nat) : async Int{
        let n : ?DAONeuron.Neuron = await update_neuron(neuron_id);
        var count : Float = 0;
        switch(n){
            case (null) return 0;
            case (?n1){
                if(n1.state == #locked)
                    count := Float.fromInt(n1.amount) * ageBonus(n1.age) * delayBonus(n1.delaytime);
                if(n1.state == #dissolving)
                    count := Float.fromInt(n1.amount) * delayBonus(n1.delaytime);
                if(n1.state == #dissolved)
                    count :=0;
            };
        };
        return Float.toInt(count);
    };
    public shared({caller}) func getvotingPower() : async Int{

        //let p = Iter.map(Trie.iter(proposals), func (kv : (Nat, Types.Proposal)) : Types.Proposal = kv.1);
        //filter<K, V>(t : Trie<Nat, V>, f : (K, V) -> Bool) : Trie<K, V>
        let p = Trie.filter<Nat,DAONeuron.Neuron>(neurons, func (n,v) = v.owner == caller);

        var voting: Int=0;
        let p2 = Iter.toArray(Iter.map(Trie.iter(p), func (kv : (Nat, DAONeuron.Neuron)) : DAONeuron.Neuron = kv.1));
        for(e in p2.vals())
        {
            voting += await votingPower(e.id);
        };
        return voting;
    };
    public shared func get_all_neurons() : async [(Int,DAONeuron.Neuron)] {
        let result = Buffer.Buffer<(Int,DAONeuron.Neuron)>(0);

        var i: Int=0;
        let p = Iter.toArray(Iter.map(Trie.iter(neurons), func (kv : (Nat, DAONeuron.Neuron)) : DAONeuron.Neuron = kv.1));
        for(element in p.vals())
        {
            var n :?DAONeuron.Neuron = await update_neuron(element.id);
            switch(n){
                case(null) i+=1;
                case(?n1) {
                result.add(element.id, n1);
                i+=1;};
            };
            
        };
        return Buffer.toArray<(Int,DAONeuron.Neuron)>(result);
    };


   /// DAO
    func enforcement(t: Text): async (){
        Webpage.leave_message(t);
    };

    func proposal_put(id : Nat, proposal : Types.Proposal) {
        proposals := Trie.put(proposals, Types.proposal_key(id), Nat.equal, proposal).0;
    };
    func proposal_get(id : Nat) : ?Types.Proposal = Trie.get(proposals, Types.proposal_key(id), Nat.equal);

    public shared({caller}) func submit_proposal(payload : Text, limitation : Types.VoteRequire) : async Types.Result<Nat, Text> {
        let temp = await token.icrc1_balance_of({owner = caller;subaccount = null;});
        if ( temp == 0) {
            return #err("Caller not a part of DAO") };

        let proposal_id = next_proposal_id;
            next_proposal_id += 1;
        var limit : Nat = switch(limitation.limit_to_vote) {
            case null Types.oneToken.amount_e8s;
            case (?Nat) Nat;
            };
        var threshold : Nat = switch(limitation.proposal_vote_threshold) {
            case null 100*Types.oneToken.amount_e8s;
            case (?Nat) Nat;
            };
        if(limit < 1){ limit := Types.oneToken.amount_e8s};
        if(threshold < 100*Types.oneToken.amount_e8s){ threshold := 100*Types.oneToken.amount_e8s};

        //if (proposal_vote_threshold == null){proposal_vote_threshold := 100*Types.oneToken};
        let proposal : Types.Proposal = {
            id = proposal_id;
            timestamp = Time.now();
            proposer = caller;
            payload;
            state = #open;
            votes_yes = Types.zeroToken;
            votes_no = Types.zeroToken;
            voters = List.nil();
            method = limitation.method;
            limit_to_vote = limit;
            proposal_vote_threshold = threshold;
        };
        proposal_put(proposal_id, proposal);
        #ok(proposal_id);
    };
    public shared query func get_proposal(proposal_id: Nat) : async ?Types.Proposal {
        proposal_get(proposal_id);
    };
    public shared query (msg) func whoami() : async Principal {
        return msg.caller;
    };
    public shared query func get_all_proposals() : async [(Int,Types.Proposal)] {
        let result = Buffer.Buffer<(Int,Types.Proposal)>(0);

        var i: Int=0;
        let p = Iter.toArray(Iter.map(Trie.iter(proposals), func (kv : (Nat, Types.Proposal)) : Types.Proposal = kv.1));
        for(element in p.vals())
        {
            result.add((element.id, element));
            i+=1;
        };
        return Buffer.toArray<(Int,Types.Proposal)>(result);
    };

    public shared({caller}) func vote(args: Types.VoteArgs) : async Types.Result<Types.ProposalState, Text> {
        switch (await get_proposal(args.proposal_id)) {
        case null { #err("No proposal with ID " # debug_show(args.proposal_id) # " exists") };
        case (?proposal) {
            var state = proposal.state;
            if (state != #open) {
                return #err("Proposal " # debug_show(args.proposal_id) # " is not open for voting");
            };

            switch (await token.icrc1_balance_of({owner = caller;subaccount = null;})) { // will change to neuron
            case 0 { return #err("Caller does not have any tokens to vote with") };
            case (amount_e8s) {
                if(amount_e8s < proposal.limit_to_vote){ return #err("Caller has not meet the limit tokens required, which is " # debug_show(proposal.limit_to_vote))  };
                
                var voting_tokens : Int = amount_e8s;
                if(proposal.method == #quadratic){voting_tokens := 100000000 * Float.toInt(Float.sqrt(Float.fromInt(amount_e8s/100000000)))};

                if (List.some(proposal.voters, func (e : Principal) : Bool = e == caller)) {
                    return #err("Already voted");
                };
                
                var votes_yes = proposal.votes_yes.amount_e8s;
                var votes_no = proposal.votes_no.amount_e8s;
                switch (args.vote) {
                case (#yes) { votes_yes += voting_tokens };
                case (#no) { votes_no += voting_tokens };
                };
                let voters = List.push(caller, proposal.voters);

                if (votes_yes >= proposal.proposal_vote_threshold) {
                    state := #accepted;
                    await enforcement(proposal.payload);
                };
                
                if (votes_no >= proposal.proposal_vote_threshold) {
                    state := #rejected;
                };

                let updated_proposal = {
                    id = proposal.id;
                    votes_yes = { amount_e8s = votes_yes };                              
                    votes_no = { amount_e8s = votes_no };
                    voters;
                    state;
                    timestamp = proposal.timestamp;
                    proposer = proposal.proposer;
                    payload = proposal.payload;
                    method = proposal.method;
                    limit_to_vote = proposal.limit_to_vote;
                    proposal_vote_threshold = proposal.proposal_vote_threshold;
                };
                proposal_put(args.proposal_id, updated_proposal);
            };
            };
            #ok(state)
            };
        };
    };


    /*
    vote
    modify_parameters
    quadratic_voting
    createNeuron
    dissolveNeuron 
    */
}