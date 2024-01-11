// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IDAI } from "./interfaces/IDAI.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IUSDT } from "./interfaces/IUSDT.sol";
import { IUSDC } from "./interfaces/IUSDC.sol";

IDAI constant DAI = IDAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);
ILido constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
IUSDC constant USDC = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
IUSDT constant USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);

uint256 constant _RAY = 10 ** 27;
