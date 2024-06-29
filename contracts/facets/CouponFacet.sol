// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC1155Facet } from "./ERC1155Facet.sol";
import "@prb/math/src/UD60x18.sol";
import { BondStorage } from "./BondStorage.sol";
import { OwnershipFacet } from "./OwnershipFacet.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ContextFacet } from "./ContextFacet.sol";

contract CouponFacet is BondStorage, OwnershipFacet, ContextFacet {
    event CouponStatusChanged(uint256 bondId, uint256 lineNumber);

    error NotAllClaimsReceivedForNextPayment();
    // claim coupon (+ interest)

    function claimCoupon(uint256 _bondId, address _buyer) external returns (uint256) {
        BondParams storage _bondDetails = bondStorage(_bondId);
        uint256 userBalance = ERC1155Facet(address(this)).balanceOf(_buyer, _bondId);
        require(userBalance != 0);
        uint256 interestAmount =
            convert(mul(ud60x18(userBalance), ud60x18(_bondDetails.__netCouponRates[_bondDetails.__currentLine])));
        uint256 capitalAmount =
            convert(mul(ud60x18(userBalance), ud60x18(_bondDetails.__capitalRepayment[_bondDetails.__currentLine])));
        _bondDetails.__nextInterestAmount += userBalance;
        _bondDetails.__nextCapitalAmount += userBalance;

        if (
            _bondDetails.__nextCapitalAmount == _bondDetails.__issuedAmount
                && _bondDetails.__nextInterestAmount == _bondDetails.__issuedAmount
        ) {
            _bondDetails.__allClaimsReceived = true;
        }
        return interestAmount + capitalAmount;
    }

    // withdraw coupon (with interest)
    function withdrawCouponClaim(uint256 _bondId, address _buyer) external {
        BondParams storage _bondDetails = bondStorage(_bondId);
        if (!_bondDetails.__allClaimsReceived) {
            revert NotAllClaimsReceivedForNextPayment();
        }

        uint256 userBalance = ERC1155Facet(address(this)).balanceOf(_buyer, _bondId);
        uint256 interestAmount =
            convert(mul(ud60x18(userBalance), ud60x18(_bondDetails.__netCouponRates[_bondDetails.__currentLine])));
        uint256 tokenAmount = userBalance * _bondDetails.__coupure + interestAmount;
        uint256 currentAllowance = ERC20(_bondDetails.__currencyAddress).allowance(_bondDetails.__issuer, address(this));
        require(currentAllowance >= tokenAmount, "ERC20: transfer amount exceeds allowance");
        // slither-disable-next-line all
        bool success = ERC20(_bondDetails.__currencyAddress).transferFrom(_bondDetails.__issuer, _buyer, tokenAmount);
        require(success, "ERC20: transfer failed");
        require(_bondDetails.__nextInterestAmount >= userBalance, "Underflow detected in next interest amount");

        require(_bondDetails.__nextCapitalAmount >= userBalance, "Underflow detected in next capital amount");
        unchecked {
            _bondDetails.__nextCapitalAmount -= userBalance;
            _bondDetails.__nextInterestAmount -= userBalance;
        }
        if (_bondDetails.__nextInterestAmount == 0 && _bondDetails.__nextCapitalAmount == 0) {
            _bondDetails.__couponStatus[_bondDetails.__currentLine] = CouponStatus.Executed;
            emit CouponStatusChanged(_bondId, _bondDetails.__currentLine);
            _bondDetails.__currentLine += 1;
            _bondDetails.__allClaimsReceived = false;
        }
    }

    function getSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = CouponFacet.claimCoupon.selector;
        selectors[1] = CouponFacet.withdrawCouponClaim.selector;

        return selectors;
    }
}
