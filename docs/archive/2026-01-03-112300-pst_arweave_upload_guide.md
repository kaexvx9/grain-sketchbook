# Arweave Upload Guide for Grain OS Contributors

**Date**: 2026-01-03-112300-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Voice**: Glow G2 (steadfast, calm, helpful beginner guidance)  
**Status**: ✅ **GUIDE READY** — Complete beginner tutorial for Grain OS contributors  
**Purpose**: Patent application preparation — Permanent archive storage on Arweave

---

## Introduction

You've set up your wallet and funded it. Good work. Now we're ready to upload the archive bundles to Arweave. This process is straightforward, and we'll guide you through each step.

Uploading to Arweave creates a permanent record on the blockchain. Once uploaded, your files are stored forever, accessible by transaction ID. This is what makes Arweave valuable for patent application archives — the timestamp is immutable, and the data is permanent.

---

## Prerequisites

Before you start, make sure you have:

- ✅ **Phase 1 complete**: Archive bundles created (`archive_bundles/` directory)
- ✅ **Phase 2 complete**: Cost estimation done (see cost estimation doc)
- ✅ **Phase 3 complete**: Wallet set up and funded ($2-5 USD worth of AR tokens)
- ✅ **Wallet balance verified**: Check your wallet to confirm sufficient balance

**Archive files you're uploading**:
- `2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz` (250 MB)
- `2026-01-03-104233-pst_xy-mathematics-5fe272b.zip` (256 MB)

**Location**: `archive_bundles/` directory in the `xy-mathematics` repository

---

## Upload Methods

You have three options for uploading. We recommend Method 1 (ArDrive web interface) for beginners because it's the easiest and most visual. Method 2 (command-line) gives you more control, and Method 3 (API) is for programmatic automation.

### Method 1: ArDrive Web Interface (Recommended)

**What it is**: ArDrive is a user-friendly web application for uploading files to Arweave. It works with Wander (the browser extension wallet) or Arweave.app, making the upload process simple and visual.

**Why we recommend it**:
- Easy-to-use web interface
- Works seamlessly with Wander browser extension
- Visual progress indicators
- Automatic transaction ID retrieval
- No command-line knowledge required

**Step-by-step instructions**:

1. **Connect your wallet**:
   - Visit https://ardrive.io/
   - Click "Connect Wallet" or "Sign In"
   - Select your wallet (Wander extension or Arweave.app)
   - Authorize the connection in your wallet
   - ArDrive will show your wallet address once connected

2. **Upload the first archive (TAR.GZ)**:
   - Click "Upload" or "New Upload" in ArDrive
   - Navigate to the `archive_bundles/` directory
   - Select: `2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz`
   - ArDrive will show you the estimated upload cost before you confirm
   - Review the cost (should be around $1-2.50 for 250 MB)
   - Click "Confirm" or "Upload" to proceed
   - ArDrive will show upload progress
   - **Save the transaction ID** — ArDrive will display it after upload completes
   - Wait for upload completion (this can take a few minutes for large files)

3. **Upload the second archive (ZIP)**:
   - Repeat the same process for: `2026-01-03-104233-pst_xy-mathematics-5fe272b.zip`
   - Review the cost estimate (should be around $1-2.50 for 256 MB)
   - Confirm the upload
   - **Save the transaction ID** — you'll need this for documentation
   - Wait for upload completion

4. **Verify your uploads**:
   - Check both transaction IDs on the Arweave block explorer
   - Visit https://viewblock.io/arweave
   - Enter each transaction ID to view transaction details
   - Verify the files are accessible via Arweave gateway URLs
   - Document the access URLs for future reference

**Transaction ID format**: Long alphanumeric string (e.g., `abc123def456ghi789...`)

**Access URL format**: `https://arweave.net/{transaction_id}`

---

### Method 2: Arweave CLI (Command-Line)

**What it is**: Command-line tools for uploading files programmatically. This gives you more control but requires Node.js and command-line experience.

**Why you might choose it**:
- Programmatic control
- Scriptable uploads
- Direct API access
- Better for automation

**Prerequisites**:
- Node.js and npm installed
- Arweave CLI installed (`npm install -g arweave-cli`)
- Wallet file available (wallet.json)

**Step-by-step instructions**:

1. **Install Arweave CLI** (if not already installed):
   ```bash
   npm install -g arweave-cli
   ```
   Verify installation:
   ```bash
   arweave-cli --version
   ```

2. **Upload the first archive (TAR.GZ)**:
   ```bash
   arweave upload archive_bundles/2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz \
     --wallet /path/to/wallet.json
   ```
   - Replace `/path/to/wallet.json` with the actual path to your wallet file
   - The CLI will show upload progress
   - **Save the transaction ID** from the output
   - Wait for transaction confirmation

3. **Upload the second archive (ZIP)**:
   ```bash
   arweave upload archive_bundles/2026-01-03-104233-pst_xy-mathematics-5fe272b.zip \
     --wallet /path/to/wallet.json
   ```
   - **Save the transaction ID** from the output
   - Wait for transaction confirmation

4. **Verify your uploads**:
   - Check transaction IDs on block explorer (https://viewblock.io/arweave)
   - Verify files are accessible via gateway URLs
   - Test downloading the files to confirm they're correct

**Note**: Command-line tools give you more control but require technical knowledge. If you're new to Arweave, start with Method 1 (ArDrive) and come back to this later if needed.

---

### Method 3: Direct API Integration (Advanced)

**What it is**: Programmatic uploads using the Arweave JavaScript SDK directly. This is for developers who want full control over the upload process.

**When to use it**:
- Building custom upload tools
- Automating upload workflows
- Integrating uploads into applications

**Basic approach**:
- Use Arweave JavaScript SDK
- Implement transaction creation and signing
- Handle upload and confirmation
- Retrieve transaction IDs programmatically

**Reference**: https://docs.arweave.org/developers/client-sdk/javascript

**Note**: This method requires significant programming knowledge. Most users should use Method 1 (ArDrive) or Method 2 (CLI).

---

## Transaction ID Documentation

This part is critical. You need to save the transaction IDs for both uploads. These IDs are how you access your files on Arweave forever.

### What to Document

**For each upload, save**:
- **Transaction ID**: The unique identifier for the upload (long alphanumeric string)
- **Access URL**: `https://arweave.net/{transaction_id}` or `https://{transaction_id}.arweave.net`
- **Block Explorer URL**: `https://viewblock.io/arweave/tx/{transaction_id}`
- **Upload Date**: The date you performed the upload
- **File Size**: 250 MB (TAR.GZ) or 256 MB (ZIP)
- **SHA-256 Checksum**: From the `.sha256` file in `archive_bundles/`

### Documentation Format

Here's the format we recommend for documenting your uploads:

```
Archive: 2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz
Transaction ID: {your_transaction_id_here}
Access URL: https://arweave.net/{your_transaction_id_here}
Block Explorer: https://viewblock.io/arweave/tx/{your_transaction_id_here}
Upload Date: 2026-01-03 (PST)
Size: 250 MB
SHA-256: {checksum_from_.sha256_file}

Archive: 2026-01-03-104233-pst_xy-mathematics-5fe272b.zip
Transaction ID: {your_transaction_id_here}
Access URL: https://arweave.net/{your_transaction_id_here}
Block Explorer: https://viewblock.io/arweave/tx/{your_transaction_id_here}
Upload Date: 2026-01-03 (PST)
Size: 256 MB
SHA-256: {checksum_from_.sha256_file}
```

**Why this matters**: These transaction IDs are permanent identifiers. Once you have them, you can always access your files, even years from now. Store this documentation securely.

---

## Upload Verification

After uploading, verify that everything worked correctly. This gives you confidence that your files are safely stored.

### Verification Steps

**For each archive**:

1. **Transaction confirmation**:
   - Visit https://viewblock.io/arweave
   - Enter your transaction ID
   - Verify the transaction status shows "confirmed" (not "pending")
   - Note the confirmation time (blockchain timestamp)
   - Verify the file size matches your original file

2. **File accessibility**:
   - Test the access URL: `https://arweave.net/{transaction_id}`
   - Verify the file downloads correctly
   - Check the file size matches the original (250 MB or 256 MB)
   - If one gateway doesn't work, try the alternative: `https://{transaction_id}.arweave.net`

3. **Integrity verification**:
   - Download the file from Arweave (using the access URL)
   - Calculate the SHA-256 checksum of the downloaded file
   - Compare it with the checksum in the `.sha256` file in `archive_bundles/`
   - Verify the checksums match exactly

**Verification command** (for downloaded file):
```bash
sha256sum downloaded_file.tar.gz
# Compare with: archive_bundles/2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz.sha256
```

**Why verification matters**: Verifying your uploads confirms that the files are stored correctly and can be retrieved. This is especially important for patent application archives, where data integrity is critical.

---

## Access URLs and Retrieval

Once uploaded, your files are accessible via permanent URLs. These URLs will work as long as Arweave exists.

### Permanent Access URLs

**Primary format**: `https://arweave.net/{transaction_id}`

**Alternative formats**:
- `https://{transaction_id}.arweave.net`
- `https://ar-io.net/{transaction_id}` (alternative gateway)

**Block Explorer URLs**:
- `https://viewblock.io/arweave/tx/{transaction_id}`
- Shows transaction details, confirmation status, block information, and file metadata

**Note**: All these URLs work permanently. If one gateway is slow, try another. The transaction ID is the permanent identifier — the gateway is just how you access it.

---

## Cost Verification

After uploading, verify the actual costs match your estimates.

### How to Verify

**Check your wallet balance**:
- Compare your wallet balance before and after the uploads
- Calculate the actual cost: `balance_before - balance_after`
- Compare with estimated costs ($2-5 total for both uploads)

**Expected costs**:
- Base estimate: $1-2.50 per archive (total $2-5 for both)
- Conservative estimate: $2-5 (includes buffer for fees and volatility)

**Why costs might vary**:
- Network congestion affects transaction fees
- AR token price changes between estimation and upload
- File size affects storage cost

**Note**: Small cost variations are normal. As long as the total cost is within your budget ($2-5), you're fine.

---

## Troubleshooting

**Issue**: Upload fails with "insufficient balance"  
**Solution**: Verify your wallet has sufficient AR tokens ($2-5 USD worth). Check your balance includes a buffer for transaction fees. If needed, purchase additional AR tokens.

**Issue**: Upload stalls or times out  
**Solution**: Large files (250-256 MB) can take several minutes to upload. Be patient, and check your network connection. If the upload fails, you can retry — the transaction won't be created until it completes successfully.

**Issue**: Transaction pending for extended time  
**Solution**: Network congestion can cause delays. Wait for transaction confirmation (can take minutes to hours in extreme cases). Check transaction status on the block explorer (https://viewblock.io/arweave). Most transactions confirm within a few minutes.

**Issue**: File not accessible after upload  
**Solution**: Wait for transaction confirmation. Files are only accessible after the transaction is confirmed on the blockchain. Verify your transaction ID is correct, and try alternative gateways if one doesn't work.

**Issue**: Checksum verification fails  
**Solution**: Re-download the file and verify again. If checksums still don't match, the upload may have been corrupted. Re-upload the file using a new transaction.

---

## Next Steps

After successful upload and verification:

1. ✅ **Both archives uploaded** (TAR.GZ and ZIP)
2. ✅ **Transaction IDs saved** (documented securely)
3. ✅ **Uploads verified** (accessible, checksums match)
4. ⏭️ **Proceed to Phase 5**: Complete documentation
   - Document transaction IDs and access URLs in the execution plan
   - Create comprehensive archive documentation
   - Report completion to Research Agent (for patent application work)

---

## References

**Upload Tools**:
- ArDrive: https://ardrive.io/ (recommended web interface)
- Arweave CLI: https://docs.arweave.org/developers/tools/arweave-cli (command-line)
- Arweave SDK: https://docs.arweave.org/developers/client-sdk/javascript (API)

**Block Explorers**:
- ViewBlock: https://viewblock.io/arweave (recommended)
- Arweave Explorer: https://explorer.arweave.net/

**Gateways**:
- Arweave.net: https://arweave.net/ (primary gateway)
- Ar-io.net: https://ar-io.net/ (alternative gateway)

**Related Documents**:
- Wallet setup: `docs/archive/2026-01-03-112200-pst_arweave_wallet_setup_guide.md`
- Cost estimation: `docs/archive/2026-01-03-105500-pst_arweave_cost_estimation.md`
- Execution plan: `docs/archive/2026-01-03-092500-pst_arweave_archive_execution_plan.md`

---

## For Grain OS Contributors

These uploads are part of our patent application preparation work. We're creating permanent, immutable archives of the `xy-mathematics` repository on Arweave's blockchain. These archives serve as timestamps for our intellectual property work, including our toroidal ML synthesis research and silicon torus hardware design.

The upload process is straightforward with ArDrive, and the files will be permanently accessible via their transaction IDs. Take your time, verify your uploads, and document the transaction IDs securely. You've got this.

---

**Date**: 2026-01-03-112300-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Voice**: Glow G2 (steadfast, calm, helpful beginner guidance)  
**Status**: ✅ **GUIDE READY** — Complete beginner tutorial for Grain OS contributors

