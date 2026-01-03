# Arweave Wallet Setup Guide

**Date**: 2026-01-03-110600-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **GUIDE READY** — Phase 3 preparation for Arweave archive upload  
**Purpose**: Patent application preparation — Permanent archive storage

---

## Executive Summary

This guide provides step-by-step instructions for setting up an Arweave wallet and acquiring AR tokens needed for uploading the `xy-mathematics` repository archives. This is Phase 3 of the Arweave archive task.

**Required Budget**: $2.00-5.00 USD worth of AR tokens  
**Archive Size**: ~506 MB total (250 MB TAR.GZ + 256 MB ZIP)  
**Estimated Cost**: $1.00-2.50 (base), $2.00-5.00 (conservative with buffer)

---

## Wallet Options

### Option 1: ArConnect Browser Extension (Recommended for Web Upload)

**Advantages**:
- Easy browser-based interface
- Compatible with ArDrive web upload tool
- Secure wallet management
- No command-line setup required

**Setup Steps**:
1. Install ArConnect browser extension (Chrome, Firefox, or Brave)
2. Create new wallet or import existing wallet
3. **Securely backup seed phrase** (critical - store in safe place)
4. Fund wallet with AR tokens ($2.00-5.00 USD worth)
5. Verify wallet balance

**Download**: https://www.arconnect.io/

---

### Option 2: Arweave.app Web Wallet

**Advantages**:
- Web-based (no extension installation)
- Simple interface
- Compatible with web upload tools

**Setup Steps**:
1. Visit https://arweave.app/
2. Create new wallet or import existing wallet
3. **Securely backup seed phrase** (critical - store in safe place)
4. Fund wallet with AR tokens ($2.00-5.00 USD worth)
5. Verify wallet balance

---

### Option 3: Command-Line Tools (For Advanced Users)

**Advantages**:
- Programmatic control
- Scriptable uploads
- Direct API access

**Tools**:
- `arweave-deploy` (Node.js-based)
- Direct Arweave API integration

**Setup Steps**:
1. Install Node.js and npm
2. Install Arweave SDK or arweave-deploy tool
3. Generate wallet file (or import existing)
4. **Securely backup wallet file** (critical - store in safe place)
5. Fund wallet with AR tokens ($2.00-5.00 USD worth)
6. Verify wallet balance

---

## AR Token Acquisition

### Step 1: Purchase AR Tokens

**Exchanges** (as of 2026):
- Binance
- Coinbase
- Kraken
- Gate.io
- Other major cryptocurrency exchanges

**Steps**:
1. Create account on exchange (if needed)
2. Complete KYC verification (if required)
3. Purchase AR tokens ($2.00-5.00 USD worth, plus exchange fees)
4. Withdraw AR tokens to your Arweave wallet address

**Note**: Check current AR/USD exchange rate at time of purchase.

---

### Step 2: Transfer to Wallet

**For ArConnect/Arweave.app**:
1. Copy your wallet address from wallet interface
2. Send AR tokens from exchange to wallet address
3. Wait for transaction confirmation (typically a few minutes)
4. Verify balance in wallet

**For Command-Line**:
1. Obtain wallet address from wallet file or command-line tool
2. Send AR tokens from exchange to wallet address
3. Wait for transaction confirmation
4. Verify balance using command-line tool or block explorer

---

## Wallet Security

### Critical Security Practices

1. **Backup Seed Phrase**:
   - Write down seed phrase on paper (physical backup)
   - Store in secure location (safe, safety deposit box, etc.)
   - **Never share seed phrase with anyone**
   - Consider multiple backup locations

2. **Wallet File Backup** (for command-line):
   - Encrypt wallet file
   - Store encrypted backup in multiple secure locations
   - **Never commit wallet file to git repository**

3. **Private Key Security**:
   - Private keys provide full access to wallet
   - Never share private keys
   - Use secure password managers if storing digitally

4. **Verify Wallet Balance**:
   - Always verify wallet has sufficient balance before upload
   - Include buffer for transaction fees and volatility

---

## Balance Verification

### Check Balance

**ArConnect/Arweave.app**:
- Balance displayed in wallet interface
- Verify sufficient balance for uploads + buffer

**Command-Line**:
- Use Arweave API or SDK to check balance
- Verify balance matches expected amount

**Block Explorer**:
- Use Arweave block explorer (e.g., https://viewblock.io/arweave)
- Enter wallet address to view balance and transaction history

---

## Budget Verification

**Recommended Budget**: $2.00-5.00 USD worth of AR tokens

**Verification**:
- Check current AR/USD exchange rate
- Calculate AR tokens needed: $2.00-5.00 / AR_price_per_token
- Ensure wallet balance exceeds calculated amount
- Include small buffer for transaction fees and price volatility

**Example** (if AR = $10 per token):
- Budget: $5.00 USD
- AR tokens needed: $5.00 / $10 = 0.5 AR tokens
- Recommended: Purchase 0.6-0.7 AR tokens (includes buffer)

---

## Next Steps

After wallet setup and funding:

1. ✅ **Wallet created and funded**
2. ✅ **Balance verified** (sufficient for uploads)
3. ⏭️ **Proceed to Phase 4**: Upload archives to Arweave
   - See upload guide: `docs/archive/2026-01-03-110700-pst_arweave_upload_guide.md`

---

## Troubleshooting

### Common Issues

**Issue**: Wallet balance shows zero after transfer
- **Solution**: Wait for transaction confirmation (can take a few minutes)
- Check transaction status on block explorer

**Issue**: Exchange withdrawal pending
- **Solution**: Exchange withdrawals can take time (varies by exchange)
- Check exchange withdrawal status

**Issue**: Insufficient balance for upload
- **Solution**: Purchase additional AR tokens to meet budget requirement
- Verify balance includes buffer for fees and volatility

---

## References

**Wallet Resources**:
- ArConnect: https://www.arconnect.io/
- Arweave.app: https://arweave.app/
- Arweave Documentation: https://docs.arweave.org/

**Exchange Resources**:
- Check current AR token listings on major exchanges
- Verify exchange supports AR token withdrawals

**Cost Estimation**:
- See: `docs/archive/2026-01-03-105500-pst_arweave_cost_estimation.md`
- Recommended budget: $2.00-5.00 USD

---

**Date**: 2026-01-03-110600-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **GUIDE READY** — Wallet setup instructions complete

