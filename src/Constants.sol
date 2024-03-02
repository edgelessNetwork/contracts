// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ILido } from "./interfaces/ILido.sol";
import { IWithdrawalQueueERC721 } from "./interfaces/IWithdrawalQueueERC721.sol";

// ILido constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
// IWithdrawalQueueERC721 constant LIDO_WITHDRAWAL_ERC721 =
//     IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

// Sepolia
ILido constant LIDO = ILido(0x3e3FE7dBc6B4C189E7128855dD526361c49b40Af);
IWithdrawalQueueERC721 constant LIDO_WITHDRAWAL_ERC721 =
    IWithdrawalQueueERC721(0x1583C7b3f4C3B008720E6BcE5726336b0aB25fdd);
