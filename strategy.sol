// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";
contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 28 * BPS;
    function afterInitialize(uint256, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE; return (BASE, BASE);
    }
    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 r = trade.amountY / (24 * WAD);
        uint256 bump = r * 36 * BPS;
        uint256 target = clampFee(BASE + bump);
        if (fee < target) fee = target;
        else if (fee > BASE) {
            uint256 nf = fee * 85 / 100; fee = nf > BASE ? nf : BASE;
        }
        slots[0] = fee; return (fee, fee);
    }
    function getName() external pure override returns (string memory) { return "C"; }
}
