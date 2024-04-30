import { events, transactions } from '@amxx/graphprotocol-utils';
import { BigDecimal, BigInt, Bytes } from '@graphprotocol/graph-ts';
import {
  BalloonRateSet as BalloonRateSetEvent,
  BondInitialized as BondInitializedEvent,
  BondIssued as BondIssuedEvent,
  BondParametersEdited as BondParametersEditedEvent,
  BondsWithdrawn as BondsWithdrawnEvent,
  CampaignPaused as CampaignPausedEvent,
  CampaignStartAndEndDateSet as CampaignStartAndEndDateSetEvent,
  CampaignUnpaused as CampaignUnpausedEvent,
  CapitalAmortizationFreePeriodSet as CapitalAmortizationFreePeriodSetEvent,
  CouponsComputed as CouponsComputedEvent,
  GracePeriodSet as GracePeriodSetEvent,
  InvestorsCountChanged as InvestorsCountChangedEvent,
  IssueDateSet as IssueDateSetEvent,
  MinAndMaxAmountSet as MinAndMaxAmountSetEvent,
  RevocationsCountChanged as RevocationsCountChangedEvent,
  BondTransferred as BondTransferredEvent,
  ReservedAmountChanged as ReservedAmountChangedEvent,
  CouponStatusChanged as CouponStatusChangedEvent,
} from '../generated/diamond/BondFacet';
import {
  BalloonRateSet,
  BondInitialized,
  BondIssued,
  BondParametersEdited,
  BondsWithdrawn,
  CampaignPaused,
  CampaignStartAndEndDateSet,
  CampaignUnpaused,
  CapitalAmortizationFreePeriodSet,
  CouponsComputed,
  GracePeriodSet,
  InvestorsCountChanged,
  IssueDateSet,
  MinAndMaxAmountSet,
  RevocationsCountChanged,
  BondTransferred,
  ReservedAmountChanged,
  CouponStatusChanged,
} from '../generated/schema';
import {
  fetchBond,
  fetchBondFacet,
  fetchCouponList,
  fetchHolder,
  fetchTransfer,
} from '../fetch/diamond';

const scale = BigDecimal.fromString('1000000000000000000');

export function handleBondInitialized(event: BondInitializedEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BondInitialized(events.id(event).concat('-bondInitialized'));
  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.coupure = event.params.coupure;
  ev.interestNum = BigDecimal.fromString(event.params.interestNum.toString());
  ev.interestDen = BigDecimal.fromString(event.params.interestDen.toString());
  ev.periodicInterestRate = BigDecimal.fromString(
    event.params.periodicInterestRate.toString()
  );
  ev.withholdingTaxNum = BigDecimal.fromString(
    event.params.withholdingTaxNum.toString()
  );
  ev.withholdingTaxDen = BigDecimal.fromString(
    event.params.withholdingTaxDen.toString()
  );
  ev.periodicity = event.params.periodicity;
  ev.methodOfRepayment = event.params.methodOfRepayment;
  ev.formOfFinancing = event.params.formOfFinancing;
  ev.duration = event.params.duration;
  ev.netReturn = BigDecimal.fromString(event.params.netReturn.toString());
  ev.maxSupply = BigDecimal.fromString(event.params.maxSupply.toString()).div(
    scale
  );

  const bond = fetchBond(contract, event.params.bondId.toString());
  bond.coupure = event.params.coupure;
  bond.withholdingTaxRate = ev.withholdingTaxNum.div(ev.withholdingTaxDen);
  bond.grossInterestRate = ev.interestNum.div(ev.interestDen);
  bond.netReturn = ev.netReturn.div(scale);
  bond.periodicInterestRate = ev.periodicInterestRate.div(scale);
  bond.duration = ev.duration;
  bond.maxSupply = ev.maxSupply;
  bond.status = 'Active';

  if (ev.methodOfRepayment == BigInt.fromString('0')) {
    bond.methodOfRepayment = 'Bullet';
  } else if (ev.methodOfRepayment == BigInt.fromString('1')) {
    bond.methodOfRepayment = 'Degressive';
  } else if (ev.methodOfRepayment == BigInt.fromString('2')) {
    bond.methodOfRepayment = 'Balloon';
  } else if (ev.methodOfRepayment == BigInt.fromString('3')) {
    bond.methodOfRepayment = 'WithCapitalAmortizationFreePeriod';
  } else if (ev.methodOfRepayment == BigInt.fromString('4')) {
    bond.methodOfRepayment = 'WithGracePeriod';
  }

  if (ev.formOfFinancing == BigInt.fromString('0')) {
    bond.formOfFinancing = 'Bond';
  } else if (ev.formOfFinancing == BigInt.fromString('1')) {
    bond.formOfFinancing = 'SubordinatedBond';
  }

  if (ev.periodicity == BigInt.fromString('0')) {
    bond.periodicity = 'Annual';
  } else if (ev.periodicity == BigInt.fromString('1')) {
    bond.periodicity = 'Quarterly';
  } else if (ev.periodicity == BigInt.fromString('2')) {
    bond.periodicity = 'Monthly';
  }
  ////ev.save() ;
  bond.save();
}

export function handleBondParametersEdited(
  event: BondParametersEditedEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BondParametersEdited(
    events.id(event).concat('-bondParametersEdited')
  );
  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.coupure = event.params.coupure;
  ev.interestNum = BigDecimal.fromString(event.params.interestNum.toString());
  ev.interestDen = BigDecimal.fromString(event.params.interestDen.toString());
  ev.periodicInterestRate = BigDecimal.fromString(
    event.params.periodicInterestRate.toString()
  );
  ev.withholdingTaxNum = BigDecimal.fromString(
    event.params.withholdingTaxNum.toString()
  );
  ev.withholdingTaxDen = BigDecimal.fromString(
    event.params.withholdingTaxDen.toString()
  );
  ev.periodicity = event.params.periodicity;
  ev.methodOfRepayment = event.params.methodOfRepayment;
  ev.formOfFinancing = event.params.formOfFinancing;
  ev.duration = event.params.duration;
  ev.netReturn = BigDecimal.fromString(event.params.netReturn.toString());
  ev.maxSupply = BigDecimal.fromString(event.params.maxSupply.toString()).div(
    scale
  );

  const bond = fetchBond(contract, event.params.bondId.toString());
  bond.coupure = event.params.coupure;
  bond.withholdingTaxRate = ev.withholdingTaxNum.div(ev.withholdingTaxDen);
  bond.grossInterestRate = ev.interestNum.div(ev.interestDen);
  bond.netReturn = ev.netReturn.div(scale);
  bond.periodicInterestRate = ev.periodicInterestRate.div(scale);
  bond.duration = ev.duration;
  bond.maxSupply = ev.maxSupply;

  if (ev.methodOfRepayment == BigInt.fromString('0')) {
    bond.methodOfRepayment = 'Bullet';
  } else if (ev.methodOfRepayment == BigInt.fromString('1')) {
    bond.methodOfRepayment = 'Degressive';
  } else if (ev.methodOfRepayment == BigInt.fromString('2')) {
    bond.methodOfRepayment = 'Balloon';
  } else if (ev.methodOfRepayment == BigInt.fromString('3')) {
    bond.methodOfRepayment = 'WithCapitalAmortizationFreePeriod';
  } else if (ev.methodOfRepayment == BigInt.fromString('4')) {
    bond.methodOfRepayment = 'WithGracePeriod';
  }

  if (ev.formOfFinancing == BigInt.fromString('0')) {
    bond.formOfFinancing = 'Bond';
  } else if (ev.formOfFinancing == BigInt.fromString('1')) {
    bond.formOfFinancing = 'SubordinatedBond';
  }

  if (ev.periodicity == BigInt.fromString('0')) {
    bond.periodicity = 'Annual';
  } else if (ev.periodicity == BigInt.fromString('1')) {
    bond.periodicity = 'Quarterly';
  } else if (ev.periodicity == BigInt.fromString('2')) {
    bond.periodicity = 'Monthly';
  }
  ////ev.save() ;
  bond.save();
}

export function handleCouponsComputed(event: CouponsComputedEvent): void {
  const contract = fetchBondFacet(event.address, '0');

  const ev = new CouponsComputed(events.id(event).concat('-couponsComputed'));
  const couponList = fetchCouponList(contract, event.params.bondId.toString());
  const bond = fetchBond(contract, event.params.bondId.toString());
  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;

  const capitalAndInterest: BigDecimal[] = [];
  const remainingCapital: BigDecimal[] = [];
  const grossInterest: BigDecimal[] = [];
  const netInterest: BigDecimal[] = [];
  const capitalRepayments: BigDecimal[] = [];
  const stepUpDownFee: BigDecimal[] = [];
  const grossInterestRate: BigDecimal[] = [];
  const netInterestRate: BigDecimal[] = [];
  const newDates: BigInt[] = [];
  const status: String[] = [];
  couponList.interestTotal = BigDecimal.fromString('0');
  couponList.totalToBeRepaid = BigDecimal.fromString('0');
  for (let i = 0; i < event.params.remainingCapital.length; i++) {
    status.push('Todo');
    capitalAndInterest.push(
      BigDecimal.fromString(event.params.netCouponRates[i].toString())
        .plus(
          BigDecimal.fromString(event.params.capitalRepayments[i].toString())
        )
        .div(scale)
    );

    remainingCapital.push(
      BigDecimal.fromString(event.params.remainingCapital[i].toString()).div(
        scale
      )
    );
    if (i == 0) {
      couponList.totalToBeRepaid = remainingCapital[i];
    }
    grossInterest.push(
      BigDecimal.fromString(event.params.grossCouponRates[i].toString()).div(
        scale
      )
    );
    netInterest.push(
      BigDecimal.fromString(event.params.netCouponRates[i].toString()).div(
        scale
      )
    );
    couponList.interestTotal = couponList.interestTotal.plus(netInterest[i]);
    couponList.totalToBeRepaid = couponList.totalToBeRepaid.plus(
      netInterest[i]
    );
    capitalRepayments.push(
      BigDecimal.fromString(event.params.capitalRepayments[i].toString()).div(
        scale
      )
    );
    stepUpDownFee.push(BigDecimal.fromString('0'));
    grossInterestRate.push(bond.periodicInterestRate);
    netInterestRate.push(
      bond.periodicInterestRate.times(
        BigDecimal.fromString('1').minus(bond.withholdingTaxRate)
      )
    );
    newDates.push(BigInt.fromString('0'));
  }
  couponList.capitalAndInterest = capitalAndInterest;
  couponList.remainingCapital = remainingCapital;
  couponList.capitalRepayment = capitalRepayments;
  couponList.grossInterest = grossInterest;
  couponList.netInterest = netInterest;
  couponList.couponDate = event.params.couponDates;
  couponList.newCouponDate = newDates;
  couponList.stepDown = stepUpDownFee;
  couponList.stepUp = stepUpDownFee;
  couponList.fee = stepUpDownFee;
  couponList.netInterestRate = netInterestRate;
  couponList.grossInterestRate = grossInterestRate;
  couponList.feeAmount = stepUpDownFee;
  couponList.status = status;
  ev.grossCoupons = grossInterest;
  ev.netCoupons = netInterest;
  ev.capitalRepayment = capitalRepayments;
  ev.remainingCapital = remainingCapital;
  ev.couponDates = event.params.couponDates;

  couponList.save();

  ////ev.save() ;
}

/*{ "name": "emitter", "type": "Account!" },
      { "name": "transaction", "type": "Transaction!" },
      { "name": "timestamp", "type": "BigInt!" },
      { "name": "contract", "type": "BondFacet!" },
      { "name": "bondId", "type": "BigInt!" },
      { "name": "issueDate", "type": "BigInt!" },
      { "name": "issuedAmount", "type": "BigInt!" }*/

export function handleBondIssued(event: BondIssuedEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BondIssued(events.id(event).concat('-bondIssued'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.issueDate = event.params.timestamp;
  ev.issuedAmount = event.params.issuedAmount;

  bond.status = 'Issued';
  bond.issueDate = ev.issueDate;
  bond.issuedAmount = event.params.issuedAmount;

  ////ev.save() ;
  bond.save();
}

export function handleBondsWithdrawn(event: BondsWithdrawnEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BondsWithdrawn(events.id(event).concat('-bondsWithdrawn'));
  const bond = fetchBond(contract, event.params.bondId.toString());
  const hldr = fetchHolder(
    contract,
    event.params.holder,
    event.params.bondId.toString()
  );

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.holder = event.params.holder;
  ev.amount = event.params.amount;

  const holders: Bytes[] = [];
  const amount: BigInt[] = [];

  const reservingAddresses: Bytes[] = [];
  const reservedAmount: Bytes[] = [];

  //const holder = fetchAccount(event.params.holder);
  const holder = ev.holder;
  let holderExist = false;

  hldr.amount = hldr.amount.plus(ev.amount);
  if (hldr.dateOfOwnership == BigInt.fromString('0')) {
    hldr.dateOfOwnership = event.block.timestamp;
  } else {
    if (event.block.timestamp >= hldr.dateOfOwnership) {
      hldr.dateOfOwnership = event.block.timestamp;
    }
  }

  /*const hldrBonds = hldr.bondIds;
  const hldrAmounts = hldr.amount;

  const hldrBondsUpdated: BigInt[] = [];
  const hldrAmountsUpdated: BigInt[]= [];

  let holderHasBonds = false;
  for(let i = 0; i < hldrBonds.length; i++){
    if(hldrBonds[i] == ev.bondId){
      holderHasBonds = true;
      hldrAmountsUpdated.push(hldrAmounts[i].plus(ev.amount));
    }
    else{
      hldrAmountsUpdated.push(hldrAmounts[i]);
    }
    hldrBondsUpdated.push(hldrBonds[i]);
  }
  if(holderHasBonds == false){
    hldrBondsUpdated.push(ev.bondId);
    hldrAmountsUpdated.push(ev.amount);
  }

  hldr.bondIds = hldrBondsUpdated;
  hldr.amount = hldrAmountsUpdated;*/

  for (let i = 0; i < bond.holders.length; i++) {
    holders.push(bond.holders[i]);
    if (bond.holders[i] == holder) {
      holderExist = true;
      amount.push(bond.holdersAmount[i].plus(ev.amount));
    } else {
      amount.push(bond.holdersAmount[i]);
    }
  }
  if (holderExist == false) {
    holders.push(holder);
    amount.push(ev.amount);
  }
  for (let i = 0; i < bond.reservedAmountByAddresses.length; i++) {
    if (bond.reservationsByAddresses[i] != holder) {
      reservingAddresses.push(bond.reservationsByAddresses[i]);
      reservedAmount.push(bond.reservedAmountByAddresses[i]);
    }
  }

  bond.holders = holders;
  bond.holdersAmount = amount;
  bond.reservationsByAddresses = reservingAddresses;
  bond.reservedAmountByAddresses = reservedAmount;
  bond.totalAmountOfAssignedBonds.plus(ev.amount);

  ////ev.save();
  bond.save();
  hldr.save();
}

export function handleInvestorsCountChanged(
  event: InvestorsCountChangedEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new InvestorsCountChanged(
    events.id(event).concat('-investorsCountChanged')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.investorsCount = event.params.investorsCount;

  bond.investorsCount = event.params.investorsCount;
  ////ev.save() ;
  bond.save();
}

export function handleRevocationsCountChanged(
  event: RevocationsCountChangedEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new RevocationsCountChanged(
    events.id(event).concat('-revocationsCountChanged')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.revocationsCount = event.params.revocationsCount;

  bond.revocationsCount = event.params.revocationsCount;
  ////ev.save() ;
  bond.save();
}

export function handleReservedAmountChanged(
  event: ReservedAmountChangedEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new ReservedAmountChanged(
    events.id(event).concat('-reservedAmountChanged')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.reservedAmount = event.params.reservedAmount;

  bond.reservedAmount = ev.reservedAmount;
  ////ev.save() ;
  bond.save();
}

export function handleMinAndMaxAmountSet(event: MinAndMaxAmountSetEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new MinAndMaxAmountSet(
    events.id(event).concat('-minAndMaxAmountSet')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.minAmount = event.params.minAmount;
  ev.maxAmount = event.params.maxAmount;
  ev.maxAmountPerInvestor = BigDecimal.fromString(
    event.params.maxAmountPerInvestor.toString()
  );

  bond.minAmount = event.params.minAmount;
  bond.maxAmount = event.params.maxAmount;
  bond.maxAmountPerInvestor = ev.maxAmountPerInvestor;

  ////ev.save() ;
  bond.save();
}

export function handleBalloonRateSet(event: BalloonRateSetEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BalloonRateSet(events.id(event).concat('-balloonRateSet'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.balloonRateNum = BigDecimal.fromString(
    event.params.balloonRateNum.toString()
  );
  ev.balloonRateDen = BigDecimal.fromString(
    event.params.balloonRateDen.toString()
  );

  if (ev.balloonRateDen != BigDecimal.fromString('0')) {
    bond.balloonPercentage = ev.balloonRateNum.div(ev.balloonRateDen);
  } else {
    bond.balloonPercentage = BigDecimal.fromString('0');
  }
  ////ev.save() ;
  bond.save();
}

export function handleGracePeriodSet(event: GracePeriodSetEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new GracePeriodSet(events.id(event).concat('-gracePeriodSet'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.gracePeriodDuration = event.params.gracePeriodDuration;

  bond.gracePeriod = event.params.gracePeriodDuration;

  ////ev.save() ;
  bond.save();
}

export function handleCapitalAmortizationFreePeriodSet(
  event: CapitalAmortizationFreePeriodSetEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new CapitalAmortizationFreePeriodSet(
    events.id(event).concat('-capitalAmortizationFreePeriodSet')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.CapitalAmortizationPeriodDuration =
    event.params.capitalAmortizationFreePeriodDuration;
  bond.capitalAmortizationFreePeriod =
    event.params.capitalAmortizationFreePeriodDuration;

  ////ev.save() ;
  bond.save();
}

export function handleCampaignStartAndEndDateSet(
  event: CampaignStartAndEndDateSetEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new CampaignStartAndEndDateSet(
    events.id(event).concat('-campaignStartAndEndDateSet')
  );
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.campaignStartDate = event.params.startDate;
  ev.campaignEndDate = event.params.endDate;

  bond.campaignEndDate = ev.campaignEndDate;
  bond.campaignStartDate = ev.campaignStartDate;

  ////ev.save() ;
  bond.save();
}

export function handleCampaignPaused(event: CampaignPausedEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new CampaignPaused(events.id(event).concat('-campaignPaused'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  bond.paused = true;
  bond.status = 'Paused';

  ////ev.save() ;
  bond.save();
}

export function handleCampaignUnpaused(event: CampaignUnpausedEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new CampaignUnpaused(events.id(event).concat('-campaignUnpaused'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  bond.paused = false;
  bond.status = 'Active';

  ////ev.save() ;
  bond.save();
}

export function handleIssueDateSet(event: IssueDateSetEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new IssueDateSet(events.id(event).concat('-issueDateSet'));
  const bond = fetchBond(contract, event.params.bondId.toString());

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.issueDate = event.params.issueDate;

  bond.issueDate = event.params.issueDate;

  ////ev.save() ;
  bond.save();
}

export function handleBondTransferred(event: BondTransferredEvent): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new BondTransferred(events.id(event).concat('-bondTransferred'));
  const bond = fetchBond(contract, event.params.bondId.toString());
  const transfer = fetchTransfer(contract, event.params.bondTransferId);
  const oldHolder = fetchHolder(
    contract,
    event.params.oldAccount,
    event.params.bondId.toString()
  );
  const newHolder = fetchHolder(
    contract,
    event.params.newAccount,
    event.params.bondId.toString()
  );

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.oldAccount = event.params.oldAccount;
  ev.newAccount = event.params.newAccount;
  ev.amount = event.params.amount;

  oldHolder.amount = oldHolder.amount.minus(ev.amount);
  newHolder.amount = newHolder.amount.plus(ev.amount);

  if (newHolder.dateOfOwnership == BigInt.fromString('0')) {
    newHolder.dateOfOwnership = event.block.timestamp;
  } else {
    if (event.block.timestamp >= newHolder.dateOfOwnership) {
      newHolder.dateOfOwnership = event.block.timestamp;
    }
  }

  oldHolder.save();
  newHolder.save();

  transfer.amount = ev.amount;
  transfer.contract = contract.id;
  transfer.from = event.params.oldAccount;
  transfer.to = event.params.newAccount;
  transfer.bondId = event.params.bondId.toString();
  transfer.transferDate = ev.timestamp;

  transfer.save();

  ////ev.save() ;
  bond.save();
}

export function handleCouponStatusChanged(
  event: CouponStatusChangedEvent
): void {
  const contract = fetchBondFacet(event.address, '0');
  const ev = new CouponStatusChanged(
    events.id(event).concat('-CouponStatusChanged')
  );
  const couponList = fetchCouponList(contract, event.params.bondId.toString());
  const status: String[] = [];

  for (let i = 0; i < couponList.status.length; i++) {
    if (i == event.params.lineNumber.toU32()) {
      status.push('Executed');
    } else {
      status.push(couponList.status[i]);
    }
  }

  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;
  ev.contract = contract.id;
  ev.bondId = event.params.bondId;
  ev.lineNumber = event.params.lineNumber;

  couponList.save();
  ////ev.save() ;
}
