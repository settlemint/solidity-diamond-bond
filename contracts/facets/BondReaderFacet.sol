// SPDX-License-Identifier: FSL-1.1-MIT
pragma solidity ^0.8.24;

import "@prb/math/src/UD60x18.sol";
import { BokkyPooBahsDateTimeLibrary } from "../libraries/BokkyPooBahsDateTimeLibrary.sol";
import { BondStorage } from "./BondStorage.sol";

contract BondReaderFacet is BondStorage {
    function getCouponsDates(uint256 _bondId)
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        //BondDetails storage _bondDetails = __bondDetails[_bondId];
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 dateLength = _bondDetails.__couponDates.length;
        uint256[] memory day = new uint256[](dateLength);
        uint256[] memory month = new uint256[](dateLength);
        uint256[] memory year = new uint256[](dateLength);
        for (uint256 i = 0; i < dateLength; i++) {
            (uint256 y, uint256 m, uint256 d) =
                BokkyPooBahsDateTimeLibrary.timestampToDate(_bondDetails.__couponDates[i]);
            day[i] = d;
            month[i] = m;
            year[i] = y;
        }
        return (day, month, year);
    }

    function getCouponsRates(uint256 _bondId)
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        BondParams storage _bondDetails = bondStorage(_bondId);

        uint256[] memory gross = new uint256[](_bondDetails.__grossCouponRates.length);
        uint256[] memory net = new uint256[](_bondDetails.__grossCouponRates.length);
        uint256[] memory capital = new uint256[](_bondDetails.__capitalRepayment.length);
        uint256[] memory remainingCapital = new uint256[](_bondDetails.__remainingCapital.length);
        for (uint256 i = 0; i < _bondDetails.__grossCouponRates.length; i++) {
            gross[i] = _bondDetails.__grossCouponRates[i];
            net[i] = _bondDetails.__netCouponRates[i];
            capital[i] = _bondDetails.__capitalRepayment[i];
            remainingCapital[i] = _bondDetails.__remainingCapital[i];
        }
        return (gross, net, capital, remainingCapital);
    }

    function getSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = BondReaderFacet.getCouponsDates.selector;
        selectors[1] = BondReaderFacet.getCouponsRates.selector;
        return selectors;
    }
}
