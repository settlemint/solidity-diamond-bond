import { Address, BigDecimal, BigInt } from '@graphprotocol/graph-ts';
import {
  Bond,
  BondFacet,
  CouponList,
  Holder,
  Transfer,
} from '../generated/schema';
import { fetchAccount } from './account';

export function fetchBondFacet(
  address: Address,
  facetOffset: string
): BondFacet {
  const account = fetchAccount(address);
  const contractId = account.id.toHex().concat('/').concat(facetOffset);
  //let contract = BondFacet.load(account.id.toHex());
  let contract = BondFacet.load(contractId);

  if (contract == null) {
    //contract = new BondFacet(account.id.toHex());
    contract = new BondFacet(contractId);
    account.asBondFacet = contractId;
    //account.asBondFacet = contract.id;
    //contract.asAccount = account.id.toHex();

    contract.save();
    account.save();
  }

  return contract as BondFacet;
}

export function fetchCouponList(
  contract: BondFacet,
  bondId: string
): CouponList {
  let couponList = CouponList.load(bondId);
  if (couponList == null) {
    couponList = new CouponList(bondId);
    couponList.contract = contract.id;
    couponList.remainingCapital = [];
    couponList.capitalRepayment = [];
    couponList.grossInterestRate = [];
    couponList.netInterestRate = [];
    couponList.grossInterest = [];
    couponList.netInterest = [];
    couponList.stepUp = [];
    couponList.stepDown = [];
    couponList.fee = [];
    couponList.capitalAndInterest = [];
    couponList.couponDate = [];
    couponList.newCouponDate = [];
    couponList.feeAmount = [];
    couponList.status = [];
    couponList.totalToBeRepaid = BigDecimal.fromString('0');
    couponList.totalAmountRepaid = BigDecimal.fromString('0');
    couponList.capitalRepaid = BigDecimal.fromString('0');
    couponList.interestRepaid = BigDecimal.fromString('0');
    couponList.interestTotal = BigDecimal.fromString('0');
    couponList.save();
  }
  return couponList as CouponList;
}

export function fetchHolder(
  contract: BondFacet,
  account: Address,
  bondId: string
): Holder {
  const holderId = account.toString().concat('/').concat(bondId);
  let holder = Holder.load(holderId);

  if (holder == null) {
    holder = new Holder(holderId);
    holder.contract = contract.id;
    holder.account = account;
    holder.amount = BigInt.fromString('0');
    holder.bondId = bondId;
    holder.dateOfOwnership = BigInt.fromString('0');
    holder.save();
  }
  return holder;
}

export function fetchTransfer(
  contract: BondFacet,
  transferId: string
): Transfer {
  //const transferId = bondId.concat('/').concat(from).concat('/').concat(to).concat('/').concat(timestamp);
  let transfer = Transfer.load(transferId);
  if (transfer == null) {
    transfer = new Transfer(transferId);
    transfer.bondTransferId = transferId;
    transfer.contract = contract.id;
    transfer.bondId = '';
    transfer.transferDate = BigInt.fromString('0');
    transfer.amount = BigInt.fromString('0');
    transfer.save();
  }
  return transfer;
}

export function fetchBond(contract: BondFacet, bondId: string): Bond {
  let bond = Bond.load(bondId);
  if (bond == null) {
    bond = new Bond(bondId);
    bond.contract = contract.id;
    bond.coupure = BigInt.fromString('0');
    bond.grossInterestRate = BigDecimal.fromString('0');
    bond.netReturn = BigDecimal.fromString('0');
    bond.withholdingTaxRate = BigDecimal.fromString('0');
    bond.periodicInterestRate = BigDecimal.fromString('0');
    bond.holders = [];
    bond.holdersAmount = [];
    bond.reservationsByAddresses = [];
    bond.reservedAmountByAddresses = [];
    bond.reservedAmount = BigInt.fromString('0');
    bond.periodicity = '';
    bond.methodOfRepayment = '';
    bond.duration = BigInt.fromString('0');
    bond.gracePeriod = BigInt.fromString('0');
    bond.balloonPercentage = BigDecimal.fromString('0');
    bond.capitalAmortizationFreePeriod = BigInt.fromString('0');
    bond.costEmittent = BigDecimal.fromString('0');
    bond.investorsCount = BigInt.fromString('0');
    bond.revocationsCount = BigInt.fromString('0');
    bond.campaignStartDate = BigInt.fromString('0');
    bond.campaignEndDate = BigInt.fromString('0');
    bond.paused = false;
    bond.maxSupply = BigDecimal.fromString('0');
    bond.maxAmountPerInvestor = BigDecimal.fromString('0');
    bond.campaignStartDate = BigInt.fromString('0');
    bond.campaignEndDate = BigInt.fromString('0');
    bond.maxAmount = BigInt.fromString('0');
    bond.minAmount = BigInt.fromString('0');
    bond.issueDate = BigInt.fromString('0');
    bond.formOfFinancing = '';
    bond.status = '';
    bond.withdrawRef = '';
    bond.cancelRef = '';
    bond.terminated = false;
    bond.isReplacementBond = false;
    //bond.hashLockCancel =Bytes.fromHexString('');
    //bond.hashLockWithdraw = Bytes.fromHexString('');

    bond.withdrawStartTime = BigInt.fromString('0');
    bond.withdrawEndTime = BigInt.fromString('0');
    bond.cancelStartTime = BigInt.fromString('0');
    bond.cancelEndTime = BigInt.fromString('0');
    bond.issuedAmount = BigInt.fromString('0');
    bond.totalAmountOfAssignedBonds = BigInt.fromString('0');
    bond.save();
  }
  return bond as Bond;
}
