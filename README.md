# simple-swap


# 🧪 Trabajo Final Módulo 3: Implementación de SimpleSwap

## 🎯 Objetivo

Crear un contrato inteligente llamado `SimpleSwap` que permita:
- Agregar y remover liquidez.
- Intercambiar tokens.
- Obtener precios y calcular cantidades a recibir.

El contrato replicará la funcionalidad básica de Uniswap **sin depender de su protocolo**.

---

## 📢 Requerimientos

### 1️⃣ Agregar Liquidez (`addLiquidity`)

**Descripción:**  
Permite a los usuarios agregar liquidez a un par de tokens en un pool ERC-20.

**Interfaz:**
```solidity
function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
```

**Tareas:**
- Transferir tokens del usuario al contrato.
- Calcular y asignar liquidez según las reservas.
- Emitir tokens de liquidez al usuario.

**Parámetros:**
- `tokenA`, `tokenB`: Direcciones de los tokens.
- `amountADesired`, `amountBDesired`: Cantidades deseadas de tokens.
- `amountAMin`, `amountBMin`: Mínimos aceptables.
- `to`: Dirección del destinatario.
- `deadline`: Límite de tiempo para la transacción.

**Retornos:**
- `amountA`, `amountB`, `liquidity`: Cantidades efectivas y liquidez emitida.

---

### 2️⃣ Remover Liquidez (`removeLiquidity`)

**Descripción:**  
Permite a los usuarios retirar liquidez de un pool ERC-20.

**Interfaz:**
```solidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB);
```

**Tareas:**
- Quemar tokens de liquidez del usuario.
- Calcular y retornar tokens A y B.

**Parámetros:**
- `tokenA`, `tokenB`: Direcciones de los tokens.
- `liquidity`: Cantidad de tokens de liquidez a retirar.
- `amountAMin`, `amountBMin`: Mínimos aceptables.
- `to`: Dirección del destinatario.
- `deadline`: Límite de tiempo para la transacción.

**Retornos:**
- `amountA`, `amountB`: Cantidades recibidas tras retirar liquidez.

---

### 3️⃣ Intercambiar Tokens (`swapExactTokensForTokens`)

**Descripción:**  
Permite intercambiar una cantidad exacta de un token por otro.

**Interfaz:**
```solidity
function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns (uint[] memory amounts);
```

**Tareas:**
- Transferir token de entrada del usuario al contrato.
- Calcular el intercambio según reservas.
- Transferir token de salida al usuario.

**Parámetros:**
- `amountIn`: Cantidad de tokens de entrada.
- `amountOutMin`: Mínimo aceptable de tokens de salida.
- `path`: Array de direcciones de tokens (entrada → salida).
- `to`: Dirección del destinatario.
- `deadline`: Límite de tiempo para la transacción.

**Retornos:**
- `amounts`: Array con cantidades de entrada y salida.

---

### 4️⃣ Obtener el Precio (`getPrice`)

**Descripción:**  
Obtiene el precio de un token en términos de otro.

**Interfaz:**
```solidity
function getPrice(
    address tokenA,
    address tokenB
) external view returns (uint price);
```

**Tareas:**
- Obtener reservas de ambos tokens.
- Calcular y retornar el precio.

**Parámetros:**
- `tokenA`, `tokenB`: Direcciones de los tokens.

**Retorno:**
- `price`: Precio de `tokenA` en términos de `tokenB`.

---

### 5️⃣ Calcular Cantidad a Recibir (`getAmountOut`)

**Descripción:**  
Calcula cuántos tokens se recibirán al realizar un intercambio.

**Interfaz:**
```solidity
function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) external pure returns (uint amountOut);
```

**Tareas:**
- Calcular y retornar la cantidad de salida.

**Parámetros:**
- `amountIn`: Cantidad de tokens de entrada.
- `reserveIn`, `reserveOut`: Reservas actuales del contrato.

**Retorno:**
- `amountOut`: Cantidad de tokens de salida.

---
