export const idlFactory = ({ IDL }) => {
  const TagUid = IDL.Text;
  const Location = IDL.Record({
    'latitude' : IDL.Float64,
    'longitude' : IDL.Float64,
  });
  const LoggedMessage = IDL.Record({
    'uid' : TagUid,
    'balance' : IDL.Nat64,
    'from' : IDL.Principal,
    'time' : IDL.Nat64,
    'message' : IDL.Text,
    'location' : IDL.Text,
  });
  const NewMessage = IDL.Record({
    'uid' : TagUid,
    'message' : IDL.Text,
    'location' : IDL.Opt(Location),
  });
  const ValidationIdentifier = IDL.Text;
  const AESKey = IDL.Text;
  const ValidationRequest = IDL.Record({
    'validation' : ValidationIdentifier,
    'access_code' : AESKey,
  });
  const Hex = IDL.Text;
  const ValidationResponse = IDL.Record({
    'tag' : Hex,
    'owner' : IDL.Bool,
    'wallet' : IDL.Vec(IDL.Nat8),
  });
  const ValidationError = IDL.Record({ 'msg' : IDL.Text });
  const ValidationResult = IDL.Variant({
    'Ok' : ValidationResponse,
    'Err' : ValidationError,
  });
  const BlockIndex = IDL.Nat64;
  const Tokens = IDL.Record({ 'e8s' : IDL.Nat64 });
  const TransferError = IDL.Variant({
    'TxTooOld' : IDL.Record({ 'allowed_window_nanos' : IDL.Nat64 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens }),
    'TxDuplicate' : IDL.Record({ 'duplicate_of' : BlockIndex }),
    'TxCreatedInFuture' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens }),
  });
  const TransferResult = IDL.Variant({
    'Ok' : BlockIndex,
    'Err' : TransferError,
  });
  const SDM = IDL.Service({
    'getChatLog' : IDL.Func(
        [TagUid, IDL.Opt(Location)],
        [IDL.Vec(LoggedMessage)],
        [],
      ),
    'getRegistry' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(TagUid, IDL.Principal))],
        ['query'],
      ),
    'initializeNtagle' : IDL.Func([], [], ['oneway']),
    'isAdmin' : IDL.Func([], [IDL.Bool], []),
    'postMessage' : IDL.Func([NewMessage], [IDL.Vec(LoggedMessage)], []),
    'tagBalance' : IDL.Func([TagUid], [IDL.Nat64], []),
    'validateAccess' : IDL.Func([ValidationRequest], [ValidationResult], []),
    'whoami' : IDL.Func([], [IDL.Principal], []),
    'withdraw' : IDL.Func(
        [TagUid, IDL.Vec(IDL.Nat8), IDL.Nat64],
        [TransferResult],
        [],
      ),
  });
  return SDM;
};
export const init = ({ IDL }) => { return []; };
