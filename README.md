# Bonus Delay - Performance Bonus Release Contract

A smart contract built on the Stacks blockchain using Clarity that manages time-locked performance bonuses with automated release mechanisms.

## Overview

This contract enables organizations to set up performance-based bonuses that are time-locked and automatically released when both time and performance conditions are met. It provides a transparent, trustless system for employee compensation with built-in performance tracking.

## Features

- **Time-Locked Releases**: Bonuses are locked for a specified period (measured in blocks)
- **Performance-Based Unlocking**: Requires meeting performance targets before claiming
- **Automated Distribution**: Self-executing bonus claims when conditions are met
- **Owner Controls**: Administrative functions for bonus creation and management
- **Multi-Employee Support**: Handles multiple employees and bonuses simultaneously
- **Fund Management**: Built-in contract funding and withdrawal capabilities

## Contract Architecture

### Data Structures

- **Bonuses Map**: Stores individual bonus details including amounts, targets, and status
- **Employee Bonuses Map**: Tracks bonus counts per employee
- **Time Tracking**: Uses block height for reliable time-based conditions

### Key Components

- **Bonus Creation**: Admin function to establish new bonus agreements
- **Performance Updates**: System to record actual performance metrics
- **Claim Mechanism**: Employee-triggered bonus collection
- **Fund Management**: Contract funding and withdrawal controls

## Getting Started

### Prerequisites

- Stacks wallet with STX tokens
- Access to a Stacks testnet/mainnet node
- Clarity CLI or compatible development environment

### Deployment

1. **Deploy the Contract**
   ```bash
   clarinet deploy --testnet
   ```

2. **Fund the Contract**
   ```clarity
   (contract-call? .bonus-delay fund-contract u10000000) ;; Fund with 10 STX
   ```

3. **Create Your First Bonus**
   ```clarity
   (contract-call? .bonus-delay create-bonus 
     'ST1EMPLOYEE123... 
     u1000000          ;; 1 STX bonus
     u85               ;; 85% performance target
     u1440)            ;; ~10 days delay (144 blocks/day)
   ```

## Usage Guide

### For Contract Owners

#### Creating a Bonus
```clarity
(contract-call? .bonus-delay create-bonus 
  employee-principal 
  bonus-amount 
  performance-target 
  delay-in-blocks)
```

**Parameters:**
- `employee-principal`: The employee's Stacks address
- `bonus-amount`: Bonus amount in microSTX (1 STX = 1,000,000 microSTX)
- `performance-target`: Required performance score (0-100 scale)
- `delay-in-blocks`: Lock period in blocks (~144 blocks = 1 day)

#### Updating Performance
```clarity
(contract-call? .bonus-delay update-performance bonus-id actual-performance)
```

#### Managing Funds
```clarity
;; Add funds to contract
(contract-call? .bonus-delay fund-contract amount)

;; Withdraw unused funds
(contract-call? .bonus-delay withdraw-unused-funds amount)
```

### For Employees

#### Claiming a Bonus
```clarity
(contract-call? .bonus-delay claim-bonus bonus-id)
```

**Requirements for claiming:**
- Time lock period has expired
- Performance target has been met
- Bonus hasn't been claimed already
- Contract has sufficient funds

#### Checking Bonus Status
```clarity
;; View bonus details
(contract-call? .bonus-delay get-bonus bonus-id)

;; Check if bonus is claimable
(contract-call? .bonus-delay is-bonus-claimable bonus-id)
```

## API Reference

### Read-Only Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `get-bonus` | `bonus-id: uint` | Returns bonus details |
| `get-employee-bonus-count` | `employee: principal` | Returns employee's total bonus count |
| `get-contract-balance` | None | Returns contract's STX balance |
| `is-bonus-claimable` | `bonus-id: uint` | Checks if bonus can be claimed |

### Public Functions

| Function | Access | Parameters | Description |
|----------|--------|------------|-------------|
| `create-bonus` | Owner Only | `employee, amount, target, delay` | Creates new bonus |
| `fund-contract` | Owner Only | `amount` | Adds STX to contract |
| `update-performance` | Owner Only | `bonus-id, performance` | Updates performance score |
| `claim-bonus` | Employee Only | `bonus-id` | Claims eligible bonus |
| `cancel-bonus` | Owner Only | `bonus-id` | Cancels unclaimed bonus |
| `withdraw-unused-funds` | Owner Only | `amount` | Withdraws excess funds |

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-found` | Bonus ID not found |
| u102 | `err-already-exists` | Bonus already exists |
| u103 | `err-insufficient-funds` | Contract has insufficient STX |
| u104 | `err-time-not-reached` | Time lock period not expired |
| u105 | `err-already-claimed` | Bonus already claimed |
| u106 | `err-performance-not-met` | Performance target not achieved |
| u107-u113 | Various validation errors | Input validation failures |

## Examples

### Complete Workflow Example

```clarity
;; 1. Owner deploys and funds contract
(contract-call? .bonus-delay fund-contract u5000000) ;; 5 STX

;; 2. Create bonus for employee
(contract-call? .bonus-delay create-bonus 
  'ST1EMPLOYEE123... 
  u2000000    ;; 2 STX bonus
  u90         ;; 90% performance target
  u720)       ;; 5-day lock period

;; 3. Update employee's actual performance
(contract-call? .bonus-delay update-performance u1 u95) ;; 95% performance

;; 4. After lock period, employee claims bonus
(contract-call? .bonus-delay claim-bonus u1)
```

### Checking Bonus Status

```clarity
;; Get full bonus details
(contract-call? .bonus-delay get-bonus u1)
;; Returns: {employee: ST1..., amount: u2000000, performance-target: u90, 
;;          actual-performance: u95, release-time: u123720, 
;;          created-time: u123000, claimed: false, active: true}

;; Quick claimability check
(contract-call? .bonus-delay is-bonus-claimable u1)
;; Returns: true (if all conditions met)
```

## Security Considerations

- **Owner Controls**: Only contract deployer can create bonuses and manage funds
- **Time Safety**: Uses block height for reliable time measurements
- **Double-Spend Prevention**: Prevents claiming the same bonus multiple times
- **Balance Validation**: Ensures sufficient funds before transfers
- **Access Control**: Employees can only claim their own bonuses

## Testing

### Unit Tests
```bash
clarinet test
```

