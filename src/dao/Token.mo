module {
  public type Account = { owner : Principal; subaccount : ?Subaccount };
  public type Account__1 = { owner : Principal; subaccount : ?Subaccount };
  public type ArchivedTransaction = {
    callback : QueryArchiveFn;
    start : TxIndex;
    length : Nat;
  };
  public type Balance = Nat;
  public type Balance__1 = Nat;
  public type Burn = {
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type BurnArgs = {
    memo : ?[Nat8];
    from_subaccount : ?Subaccount;
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type GetTransactionsRequest = { start : TxIndex; length : Nat };
  public type GetTransactionsRequest__1 = { start : TxIndex; length : Nat };
  public type GetTransactionsResponse = {
    first_index : TxIndex;
    log_length : Nat;
    transactions : [Transaction];
    archived_transactions : [ArchivedTransaction];
  };
  public type MetaDatum = (Text, Value);
  public type Mint = {
    to : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type Mint__1 = {
    to : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type QueryArchiveFn = shared query GetTransactionsRequest__1 -> async TransactionRange;
  public type Result = { #ok : Balance__1; #err : TransferError };
  public type Subaccount = [Nat8];
  public type SupportedStandard = { url : Text; name : Text };
  public type Timestamp = Nat64;
  public type TokenInitArgs = {
    fee : Balance;
    decimals : Nat8;
    minting_account : ?Account;
    permitted_drift : ?Timestamp;
    name : Text;
    initial_balances : [(Account, Balance)];
    transaction_window : ?Timestamp;
    min_burn_amount : ?Balance;
    max_supply : Balance;
    symbol : Text;
  };
  public type Transaction = {
    burn : ?Burn;
    kind : Text;
    mint : ?Mint__1;
    timestamp : Timestamp;
    index : TxIndex;
    transfer : ?Transfer;
  };
  public type TransactionRange = { transactions : [Transaction] };
  public type Transaction__1 = {
    burn : ?Burn;
    kind : Text;
    mint : ?Mint__1;
    timestamp : Timestamp;
    index : TxIndex;
    transfer : ?Transfer;
  };
  public type Transfer = {
    to : Account;
    fee : ?Balance;
    from : Account;
    memo : ?[Nat8];
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type TransferArgs = {
    to : Account;
    fee : ?Balance;
    memo : ?[Nat8];
    from_subaccount : ?Subaccount;
    created_at_time : ?Nat64;
    amount : Balance;
  };
  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Balance };
    #Duplicate : { duplicate_of : TxIndex };
    #BadFee : { expected_fee : Balance };
    #CreatedInFuture : { ledger_time : Timestamp };
    #TooOld;
    #InsufficientFunds : { balance : Balance };
  };
  public type TxIndex = Nat;
  public type TxIndex__1 = Nat;
  public type Value = { #Int : Int; #Nat : Nat; #Blob : [Nat8]; #Text : Text };
  public type Self = actor {
    burn : shared BurnArgs -> async Result;
    deposit_cycles : shared () -> async ();
    get_transaction : shared TxIndex__1 -> async ?Transaction__1;
    get_transactions : shared query GetTransactionsRequest -> async GetTransactionsResponse;
    icrc1_balance_of : shared query Account__1 -> async Balance__1;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Balance__1;
    icrc1_metadata : shared query () -> async [MetaDatum];
    icrc1_minting_account : shared query () -> async ?Account__1;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [SupportedStandard];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Balance__1;
    icrc1_transfer : shared TransferArgs -> async Result;
    mint : shared Mint -> async Result;
  }
}