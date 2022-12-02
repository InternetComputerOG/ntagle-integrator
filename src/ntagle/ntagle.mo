module {
  public type AESKey = Text;
  public type AccessError = { #SaltNotFound; #IntegrationNotFound };
  public type AccessRequest = { uid : TagUid; canister : Principal };
  public type AccessResponse = {
    validation : ValidationIdentifier;
    access_code : AESKey;
  };
  public type AccessResult = { #Ok : AccessResponse; #Err : AccessError };
  public type CMAC = Text;
  public type Hex = Text;
  public type ImportCMACResult = { #Ok; #Err };
  public type IntegrationResult = {
    url : Text;
    name : Text;
    description : Text;
    canister : Principal;
    image : Text;
    integrated : Bool;
  };
  public type NewIntegrationError = {
    #IntegrationAlreadyExists;
    #TagNotFound;
    #NotCanisterPrincipal;
    #IntegratorNotFound;
  };
  public type NewIntegrationRequest = { uid : TagUid; canister : Principal };
  public type NewIntegrationResponse = {
    url : Text;
    name : Text;
    description : Text;
    canister : Principal;
    image : Text;
    validation : ValidationIdentifier;
    access_code : AESKey;
  };
  public type NewIntegrationResult = {
    #Ok : NewIntegrationResponse;
    #Err : NewIntegrationError;
  };
  public type NewIntegrator = {
    url : Text;
    name : Text;
    description : Text;
    image : Text;
  };
  public type SDM = actor {
    importCMACs : shared (TagUid, [Hex]) -> async ImportCMACResult;
    isAdmin : shared () -> async Bool;
    newIntegration : shared NewIntegrationRequest -> async NewIntegrationResult;
    registerIntegrator : shared NewIntegrator -> ();
    registerTag : shared TagUid -> async TagEncodeResult;
    requestAccess : shared AccessRequest -> async AccessResult;
    scan : shared Scan -> async ScanResult;
    tagInfo : shared TagIdentifier -> async TagInfoResult;
    unlock : shared TagUid -> async UnlockResult;
    validateAccess : shared ValidationRequest -> async ValidationResult;
  };
  public type Scan = {
    ctr : TagCtr;
    uid : TagUid;
    cmac : CMAC;
    transfer_code : AESKey;
  };
  public type ScanError = { #TagNotFound; #ExpiredCount; #InvalidCMAC };
  public type ScanResponse = {
    owner_changed : Bool;
    integrations : [IntegrationResult];
    owner : Bool;
    years_left : Nat;
    locked : Bool;
    scans_left : Nat32;
  };
  public type ScanResult = { #Ok : ScanResponse; #Err : ScanError };
  public type TagCtr = Nat32;
  public type TagEncodeResult = { key : AESKey; transfer_code : AESKey };
  public type TagIdentifier = Text;
  public type TagInfoError = {
    #IntegrationNotFound;
    #TagNotFound;
    #NotAuthorized;
  };
  public type TagInfoResponse = {
    last_access_key_change : Time;
    current_user : ?Principal;
    last_ownership_change : Time;
  };
  public type TagInfoResult = { #Ok : TagInfoResponse; #Err : TagInfoError };
  public type TagUid = Text;
  public type Time = Int;
  public type UnlockError = { #TagNotFound };
  public type UnlockResponse = { transfer_code : AESKey };
  public type UnlockResult = { #Ok : UnlockResponse; #Err : UnlockError };
  public type ValidationError = {
    #Invalid;
    #IntegrationNotFound;
    #TagNotFound;
    #NotAuthorized;
    #ValidationNotFound;
    #Expired;
  };
  public type ValidationIdentifier = Text;
  public type ValidationRequest = {
    user : Principal;
    validation : ValidationIdentifier;
    access_code : AESKey;
  };
  public type ValidationResponse = {
    tag : TagIdentifier;
    last_access_key_change : Time;
    previous_user : ?Principal;
    current_user : Principal;
    last_ownership_change : Time;
  };
  public type ValidationResult = {
    #Ok : ValidationResponse;
    #Err : ValidationError;
  };
  public type Self = () -> async SDM
}