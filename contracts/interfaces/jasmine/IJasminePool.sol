// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IJasmineEATBackedPool } from "./IEATBackedPool.sol";
import { IJasmineQualifiedPool } from "./IQualifiedPool.sol";
import { IJasmineRetireablePool } from "./IRetireablePool.sol";

interface IJasminePool is IJasmineEATBackedPool, IJasmineQualifiedPool, IJasmineRetireablePool {

}
