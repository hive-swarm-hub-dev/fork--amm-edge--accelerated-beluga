// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";
contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 29 * BPS;
    function afterInitialize(uint256 ix, uint256 iy) external override returns (uint256, uint256) {
        slots[0] = BASE;
        slots[1] = BASE;
        slots[2] = wdiv(iy, ix);
        return (BASE, BASE);
    }
    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 bidFee = slots[0];
        uint256 askFee = slots[1];
        uint256 ispot = slots[2];
        uint256 cspot = wdiv(trade.reserveY, trade.reserveX);
        uint256 xAsY_i = wmul(trade.amountX, ispot);
        uint256 xAsY_c = wmul(trade.amountX, cspot);
        uint256 a = trade.amountY;
        if (xAsY_i > a) a = xAsY_i;
        if (xAsY_c > a) a = xAsY_c;
        a = a * 102 / 100;
        uint256 r = a / (24 * WAD);
        uint256 bump = r * 36 * BPS;
        if (r == 1) {
            if (a < 26 * WAD) bump = bump / 4;
            else if (a < 35 * WAD) bump = bump / 2;
            else if (a < 42 * WAD) bump = bump * 3 / 4;
        }
        if (r == 2 && a < 60 * WAD) bump = bump * 3 / 4;
        if (r == 3 && a < 95 * WAD) bump = bump * 7 / 8;
        if (r == 4 && a < 110 * WAD) bump = bump * 15 / 16;
        if (r == 5 && a < 130 * WAD) bump = bump * 31 / 32;
        if (r == 6 && a < 152 * WAD) bump = bump * 63 / 64;
        uint256 target = clampFee(BASE + bump);
        if (trade.isBuy) {
            if (askFee < target) askFee = target;
            else if (askFee > BASE) {
                uint256 nf = askFee * 85 / 100;
                askFee = nf > BASE ? nf : BASE;
            }
            if (bidFee > BASE) {
                uint256 nf = bidFee * 85 / 100;
                bidFee = nf > BASE ? nf : BASE;
            }
        } else {
            if (bidFee < target) bidFee = target;
            else if (bidFee > BASE) {
                uint256 nf = bidFee * 85 / 100;
                bidFee = nf > BASE ? nf : BASE;
            }
            if (askFee > BASE) {
                uint256 nf = askFee * 85 / 100;
                askFee = nf > BASE ? nf : BASE;
            }
        }
        slots[0] = bidFee;
        slots[1] = askFee;
        return (bidFee, askFee);
    }
    function getName() external pure override returns (string memory) { return "AsymDirectional"; }
}
