import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AESKey = string;
export type BlockIndex = bigint;
export type Hex = string;
export interface Location { 'latitude' : number, 'longitude' : number }
export interface LoggedMessage {
  'uid' : TagUid,
  'balance' : bigint,
  'from' : Principal,
  'time' : bigint,
  'message' : string,
  'location' : string,
}
export interface NewMessage {
  'uid' : TagUid,
  'message' : string,
  'location' : [] | [Location],
}
export interface SDM {
  'getChatLog' : ActorMethod<[TagUid, [] | [Location]], Array<LoggedMessage>>,
  'getRegistry' : ActorMethod<[], Array<[TagUid, Principal]>>,
  'initializeNtagle' : ActorMethod<[], undefined>,
  'isAdmin' : ActorMethod<[], boolean>,
  'postMessage' : ActorMethod<[NewMessage], Array<LoggedMessage>>,
  'tagBalance' : ActorMethod<[TagUid], bigint>,
  'validateAccess' : ActorMethod<[ValidationRequest], ValidationResult>,
  'whoami' : ActorMethod<[], Principal>,
  'withdraw' : ActorMethod<[TagUid, Uint8Array, bigint], TransferResult>,
}
export type TagUid = string;
export interface Tokens { 'e8s' : bigint }
export type TransferError = {
    'TxTooOld' : { 'allowed_window_nanos' : bigint }
  } |
  { 'BadFee' : { 'expected_fee' : Tokens } } |
  { 'TxDuplicate' : { 'duplicate_of' : BlockIndex } } |
  { 'TxCreatedInFuture' : null } |
  { 'InsufficientFunds' : { 'balance' : Tokens } };
export type TransferResult = { 'Ok' : BlockIndex } |
  { 'Err' : TransferError };
export interface ValidationError { 'msg' : string }
export type ValidationIdentifier = string;
export interface ValidationRequest {
  'validation' : ValidationIdentifier,
  'access_code' : AESKey,
}
export interface ValidationResponse {
  'tag' : Hex,
  'owner' : boolean,
  'wallet' : Uint8Array,
}
export type ValidationResult = { 'Ok' : ValidationResponse } |
  { 'Err' : ValidationError };
export interface _SERVICE extends SDM {}
