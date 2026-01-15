# Arweave Wallet Setup Guide for Grain OS Contributors

**Date**: 2026-01-03-112200-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Voice**: Glow G2 (steadfast, calm, helpful beginner guidance)  
**Status**: ✅ **GUIDE READY** — Complete beginner tutorial for Grain OS contributors  
**Purpose**: Patent application preparation — Permanent archive storage on Arweave

---

## Introduction

Hey there. Setting up a wallet for Arweave can feel like a lot, but we'll walk through this step by step. The process is straightforward once you know what to do. We're here to help you get set up safely and correctly.

This guide covers everything you need to create an Arweave wallet and fund it for uploading our repository archives. This is part of preparing permanent archives for patent application work. The process takes about fifteen minutes, and we'll make sure you understand each step.

---

## What You're Doing

You're setting up a wallet to store AR tokens (Arweave's cryptocurrency). These tokens pay for permanent storage on Arweave's blockchain. Think of it like paying for a safe deposit box that lasts forever.

**What you need**: About $2-5 USD worth of AR tokens  
**Archive size**: ~506 MB total (two archive files)  
**Estimated cost**: $1-2.50 (base estimate), $2-5 (conservative with buffer for price changes)

The cost is small, but the archive will last indefinitely. That's the value we're getting here.

---

## Wallet Options

You have three options. We recommend starting with the first one (Wander browser extension) because it's the easiest for beginners. If you're comfortable with command-line tools, option three gives you more control.

### Option 1: Wander Browser Extension (Recommended)

**What it is**: Wander is the most popular Arweave wallet (formerly called ArConnect, rebranded in 2025). It works as a browser extension, so it's always available when you need it.

**Why we recommend it**:
- Simple browser interface
- Works smoothly with ArDrive (the upload tool we'll use)
- Secure wallet management
- No command-line setup required

**Setup steps**:

1. **Install Wander**:
   - Visit https://www.wander.app/
   - Click "Download extension"
   - Install for Chrome, Firefox, Brave, or Edge
   - The extension will appear in your browser toolbar

2. **Create your wallet**:
   - Open the Wander extension
   - Click "Create new wallet" (or "Import" if you already have one)
   - Wander will generate a 12-word seed phrase
   - **Write this down on paper immediately** — this is your backup
   - Store it somewhere safe (a safe, safety deposit box, or secure location)
   - Never share your seed phrase with anyone

3. **Verify your seed phrase**:
   - Wander will ask you to confirm the seed phrase
   - Type it back in the order shown
   - This confirms you wrote it down correctly

4. **Fund your wallet**:
   - Copy your wallet address from Wander
   - Send AR tokens to this address from an exchange
   - Wait for confirmation (usually a few minutes)
   - Verify your balance in Wander

**Download**: https://www.wander.app/  
**Chrome Web Store**: https://chromewebstore.google.com/detail/wander/einnioafmpimabjcddiinlhmijaionap

---

### Option 2: Arweave.app Web Wallet

**What it is**: A web-based wallet that works in any browser without installing an extension.

**Why you might choose it**:
- No extension installation needed
- Works on any device with a browser
- Simple, clean interface

**Setup steps**:

1. **Visit Arweave.app**:
   - Go to https://arweave.app/
   - Click the "+" button in the bottom left
   - Select "Create new wallet"

2. **Save your seed phrase**:
   - Arweave.app will show you a 12-word seed phrase
   - **Write this down on paper immediately**
   - Store it securely — this is your only backup
   - Click "Click to proceed" after saving

3. **Download your key file** (optional but recommended):
   - Arweave.app will offer to download a key file (JSON)
   - Save this file securely
   - This is an additional backup method

4. **Fund your wallet**:
   - Copy your wallet address
   - Send AR tokens from an exchange to this address
   - Wait for confirmation
   - Verify your balance

---

### Option 3: Command-Line Tools (Advanced)

**What it is**: Programmatic wallet management using Node.js and the Arweave SDK.

**Why you might choose it**:
- Full programmatic control
- Scriptable uploads
- Direct API access
- Better for automation

**Setup steps**:

1. **Install Node.js and npm** (if not already installed):
   ```bash
   # Check if Node.js is installed
   node --version
   npm --version
   ```

2. **Install Arweave SDK**:
   ```bash
   npm install -g arweave-deploy
   # Or install arweave package locally
   npm install arweave
   ```

3. **Generate wallet file**:
   ```bash
   # Using arweave-deploy
   arweave-deploy generate-wallet
   # This creates a wallet.json file
   ```

4. **Backup your wallet file**:
   - **Encrypt the wallet.json file**
   - Store encrypted backup in multiple secure locations
   - **Never commit wallet.json to git** (add to .gitignore)
   - Consider storing one backup offline (USB drive in safe)

5. **Fund your wallet**:
   - Get your wallet address from the wallet file or command-line tool
   - Send AR tokens from an exchange to this address
   - Wait for confirmation
   - Verify balance using command-line tool or block explorer

**Note**: Command-line tools give you more control but require more technical knowledge. If you're new to Arweave, start with Option 1 (Wander) and come back to this later if needed.

---

## Getting AR Tokens

### Step 1: Purchase AR Tokens

You'll need to buy AR tokens from a cryptocurrency exchange. This is straightforward, but it requires a few steps.

**Exchanges that support AR tokens** (as of 2026):
- Binance
- Coinbase
- Kraken
- Gate.io
- Other major cryptocurrency exchanges

**What to do**:

1. **Create an account** (if you don't have one):
   - Choose an exchange from the list above
   - Sign up with your email
   - Complete identity verification (KYC) if required
   - This process varies by exchange but usually takes a few minutes

2. **Purchase AR tokens**:
   - Deposit funds (USD, EUR, etc.) into your exchange account
   - Navigate to the AR token trading pair (AR/USD, AR/BTC, etc.)
   - Purchase $2-5 USD worth of AR tokens (plus exchange fees)
   - Check the current AR/USD exchange rate at the time of purchase

3. **Withdraw to your wallet**:
   - Copy your Arweave wallet address (from Wander, Arweave.app, or command-line)
   - Initiate a withdrawal from the exchange to your wallet address
   - Wait for transaction confirmation (usually a few minutes)

**Note**: Exchange fees vary, and AR token prices fluctuate. We recommend purchasing slightly more than the minimum ($5-7 instead of $2-5) to account for fees and price changes.

---

### Step 2: Verify Your Balance

After sending AR tokens to your wallet, verify they arrived safely.

**For Wander or Arweave.app**:
- Open your wallet
- Check the balance displayed
- Verify it shows the amount you sent (minus network fees)

**For command-line**:
- Use the Arweave API or SDK to check balance
- Verify it matches your expected amount

**Block explorer** (works for all wallets):
- Visit https://viewblock.io/arweave
- Enter your wallet address
- View your balance and transaction history
- Confirm the transaction shows as "confirmed"

**Common issue**: If your balance shows zero after sending, wait a few minutes. Blockchain transactions take time to confirm. Check the block explorer to see if the transaction is pending or confirmed.

---

## Security Best Practices

This part is critical. Your wallet gives you access to your AR tokens, so we need to protect it properly.

### Seed Phrase Security

Your seed phrase (12 words) is the master key to your wallet. Anyone with these words can access your wallet and your tokens.

**What to do**:
- Write it down on paper (physical backup)
- Store it in a secure location (safe, safety deposit box, etc.)
- Consider multiple backup locations (home safe + safety deposit box)
- **Never share your seed phrase with anyone**
- Never store it in plain text on your computer
- Never take screenshots of your seed phrase

**What not to do**:
- Don't store it in a text file on your computer
- Don't email it to yourself
- Don't save it in cloud storage (unless encrypted)
- Don't share it with anyone, even if they claim to be support

If you lose your seed phrase, you lose access to your wallet permanently. There's no password reset. Write it down, store it safely.

---

### Wallet File Security (Command-Line Users)

If you're using command-line tools, your wallet file (wallet.json) contains your private key.

**What to do**:
- Encrypt the wallet file before storing it
- Store encrypted backups in multiple secure locations
- Add wallet.json to .gitignore (never commit it to git)
- Consider storing one backup offline (encrypted USB drive in safe)

**What not to do**:
- Never commit wallet.json to a git repository
- Never share wallet.json files
- Never store it in plain text

---

### Balance Verification

Always verify your wallet has sufficient balance before attempting uploads. Include a small buffer for transaction fees and price volatility.

**Recommended balance**: $5-7 USD worth of AR tokens (conservative estimate includes buffer)

**Before uploads**:
- Check your balance in your wallet
- Verify it exceeds the estimated upload cost ($2-5)
- Confirm you have a small buffer for fees and price changes

---

## Budget Planning

Here's how to calculate what you need.

**Recommended budget**: $2-5 USD worth of AR tokens (conservative: $5-7)

**Calculation example** (if AR = $10 per token):
- Budget: $5 USD
- AR tokens needed: $5 / $10 = 0.5 AR tokens
- Recommended purchase: 0.6-0.7 AR tokens (includes buffer)

**Price volatility**: AR token prices change. Purchase a bit more than the minimum to account for price changes between purchase and upload time.

---

## Next Steps

Once your wallet is set up and funded:

1. ✅ **Wallet created** (Wander, Arweave.app, or command-line)
2. ✅ **Seed phrase backed up** (written down and stored safely)
3. ✅ **Wallet funded** ($2-5 USD worth of AR tokens)
4. ✅ **Balance verified** (check your wallet or block explorer)

**Ready for upload**: See the upload guide (`docs/archive/2026-01-03-112300-pst_arweave_upload_guide.md`) for step-by-step instructions on uploading the archive bundles.

---

## Troubleshooting

**Issue**: Wallet balance shows zero after transfer  
**Solution**: Wait a few minutes for transaction confirmation. Check the block explorer (https://viewblock.io/arweave) to see if the transaction is pending or confirmed. Blockchain transactions take time.

**Issue**: Exchange withdrawal pending  
**Solution**: Exchange withdrawals can take time (varies by exchange, usually 5-30 minutes). Check your exchange's withdrawal status page. Most exchanges show withdrawal progress.

**Issue**: Insufficient balance for upload  
**Solution**: Purchase additional AR tokens to meet the budget requirement. Verify your balance includes a buffer for fees and price volatility. We recommend $5-7 USD worth for safety.

**Issue**: Seed phrase lost or forgotten  
**Solution**: Unfortunately, there's no recovery if you lose your seed phrase. This is by design for security. If you haven't funded the wallet yet, create a new wallet and start over. If you've already funded it, you'll need to recover the seed phrase from your backup.

---

## References

**Wallet Resources**:
- Wander: https://www.wander.app/ (formerly ArConnect, rebranded 2025)
- Arweave.app: https://arweave.app/
- Arweave Documentation: https://docs.arweave.org/

**Exchange Resources**:
- Check current AR token listings on major exchanges
- Verify your chosen exchange supports AR token withdrawals
- Compare exchange fees before purchasing

**Cost Estimation**:
- See: `docs/archive/2026-01-03-105500-pst_arweave_cost_estimation.md`
- Recommended budget: $2-5 USD (conservative: $5-7)

**Related Guides**:
- Upload guide: `docs/archive/2026-01-03-112300-pst_arweave_upload_guide.md`
- Execution plan: `docs/archive/2026-01-03-092500-pst_arweave_archive_execution_plan.md`

---

## For Grain OS Contributors

This wallet setup is part of our patent application preparation work. We're creating permanent archives of the `xy-mathematics` repository on Arweave's blockchain. These archives will serve as immutable timestamps for our intellectual property work, including our toroidal ML synthesis and silicon torus hardware research.

The process is straightforward, and we're here to help. If you run into any issues, check the troubleshooting section above or refer to the Arweave documentation. Take your time, follow the security best practices, and you'll be set up correctly.

---

**Date**: 2026-01-03-112200-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Voice**: Glow G2 (steadfast, calm, helpful beginner guidance)  
**Status**: ✅ **GUIDE READY** — Complete beginner tutorial for Grain OS contributors

