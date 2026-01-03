# Arweave Upload Guide

**Date**: 2026-01-03-110700-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **GUIDE READY** — Phase 4 preparation for Arweave archive upload  
**Purpose**: Patent application preparation — Permanent archive storage

---

## Executive Summary

This guide provides step-by-step instructions for uploading the `xy-mathematics` repository archives to Arweave. This is Phase 4 of the Arweave archive task.

**Prerequisites**:
- ✅ Phase 1 complete: Archive bundles created
- ✅ Phase 2 complete: Cost estimation done
- ✅ Phase 3 complete: Wallet set up and funded
- ✅ Wallet balance: $2.00-5.00 USD worth of AR tokens

**Archive Files**:
- `2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz` (250 MB)
- `2026-01-03-104233-pst_xy-mathematics-5fe272b.zip` (256 MB)

**Location**: `archive_bundles/` directory

---

## Upload Methods

### Method 1: ArDrive Web Interface (Recommended)

**Advantages**:
- Easy-to-use web interface
- Works with ArConnect browser extension
- Visual progress indicators
- Automatic transaction ID retrieval

**Steps**:

1. **Connect Wallet**:
   - Visit https://ardrive.io/
   - Connect ArConnect wallet or Arweave.app wallet
   - Authorize connection

2. **Upload First Archive (TAR.GZ)**:
   - Click "Upload" or "New Upload"
   - Select file: `archive_bundles/2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz`
   - Review upload cost (displayed before confirmation)
   - Confirm upload
   - **Save transaction ID** (critical - needed for documentation)
   - Wait for upload completion

3. **Upload Second Archive (ZIP)**:
   - Repeat steps for: `archive_bundles/2026-01-03-104233-pst_xy-mathematics-5fe272b.zip`
   - **Save transaction ID** (critical - needed for documentation)
   - Wait for upload completion

4. **Verify Uploads**:
   - Check transaction IDs on Arweave block explorer
   - Verify files are accessible via Arweave gateway
   - Document access URLs

---

### Method 2: Arweave CLI (Command-Line)

**Prerequisites**:
- Node.js and npm installed
- Arweave CLI installed (`npm install -g arweave-cli`)
- Wallet file available

**Steps**:

1. **Install Arweave CLI** (if not installed):
   ```bash
   npm install -g arweave-cli
   ```

2. **Upload First Archive (TAR.GZ)**:
   ```bash
   arweave upload archive_bundles/2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz \
     --wallet /path/to/wallet.json
   ```
   - **Save transaction ID** from output
   - Wait for transaction confirmation

3. **Upload Second Archive (ZIP)**:
   ```bash
   arweave upload archive_bundles/2026-01-03-104233-pst_xy-mathematics-5fe272b.zip \
     --wallet /path/to/wallet.json
   ```
   - **Save transaction ID** from output
   - Wait for transaction confirmation

4. **Verify Uploads**:
   - Check transaction IDs on block explorer
   - Verify files are accessible

---

### Method 3: Direct API Integration (Advanced)

**For programmatic uploads**:
- Use Arweave JavaScript SDK
- Implement upload logic with transaction signing
- Handle transaction confirmation
- Retrieve transaction IDs

**Reference**: https://docs.arweave.org/developers/client-sdk/javascript

---

## Transaction ID Documentation

### Critical: Save Transaction IDs

**For Each Upload**:
- **Transaction ID**: Unique identifier for each upload (e.g., `abc123def456...`)
- **Access URL**: `https://arweave.net/{transaction_id}` or `https://{transaction_id}.arweave.net`
- **Block Explorer**: `https://viewblock.io/arweave/tx/{transaction_id}`

**Documentation Format**:
```
Archive: 2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz
Transaction ID: {transaction_id}
Access URL: https://arweave.net/{transaction_id}
Block Explorer: https://viewblock.io/arweave/tx/{transaction_id}
Upload Date: 2026-01-03 (PST)
Size: 250 MB
SHA-256: {checksum from .sha256 file}

Archive: 2026-01-03-104233-pst_xy-mathematics-5fe272b.zip
Transaction ID: {transaction_id}
Access URL: https://arweave.net/{transaction_id}
Block Explorer: https://viewblock.io/arweave/tx/{transaction_id}
Upload Date: 2026-01-03 (PST)
Size: 256 MB
SHA-256: {checksum from .sha256 file}
```

---

## Upload Verification

### Verify Upload Completion

**For Each Archive**:
1. **Transaction Confirmation**:
   - Check transaction status on block explorer
   - Verify transaction is confirmed (not pending)
   - Note confirmation time (blockchain timestamp)

2. **File Accessibility**:
   - Test access URL: `https://arweave.net/{transaction_id}`
   - Verify file downloads correctly
   - Verify file size matches original (250 MB or 256 MB)

3. **Integrity Verification**:
   - Download file from Arweave
   - Calculate SHA-256 checksum
   - Compare with checksum in `.sha256` file
   - Verify checksums match

**Verification Command** (for downloaded file):
```bash
sha256sum downloaded_file.tar.gz
# Compare with: archive_bundles/2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz.sha256
```

---

## Access URLs and Retrieval

### Permanent Access URLs

**Format**: `https://arweave.net/{transaction_id}`

**Alternative Formats**:
- `https://{transaction_id}.arweave.net`
- `https://ar-io.net/{transaction_id}` (alternative gateway)

**Block Explorer URLs**:
- `https://viewblock.io/arweave/tx/{transaction_id}`
- Shows transaction details, confirmation status, block information

---

## Cost Verification

### Verify Actual Costs

**After Upload**:
- Check wallet balance (before vs. after)
- Calculate actual cost: `balance_before - balance_after`
- Compare with estimated costs
- Document actual costs for future reference

**Expected Costs**:
- Base estimate: $1.00-2.50 (for ~0.49 GB)
- Conservative estimate: $2.00-5.00 (with buffer)

---

## Troubleshooting

### Common Issues

**Issue**: Upload fails with "insufficient balance"
- **Solution**: Verify wallet has sufficient AR tokens ($2.00-5.00 worth)
- Check balance includes buffer for fees

**Issue**: Upload stalls or times out
- **Solution**: Large files can take time to upload
- Check network connection
- Retry upload if transaction not confirmed

**Issue**: Transaction pending for extended time
- **Solution**: Network congestion can cause delays
- Wait for transaction confirmation (can take minutes to hours)
- Check transaction status on block explorer

**Issue**: File not accessible after upload
- **Solution**: Wait for transaction confirmation (file accessible after confirmation)
- Verify transaction ID is correct
- Try alternative gateway if one fails

---

## Next Steps

After successful upload:

1. ✅ **Both archives uploaded**
2. ✅ **Transaction IDs saved**
3. ✅ **Uploads verified** (accessible, checksums match)
4. ⏭️ **Proceed to Phase 5**: Complete documentation
   - Document transaction IDs and access URLs
   - Create comprehensive archive documentation
   - Report completion to Research Agent

---

## References

**Upload Tools**:
- ArDrive: https://ardrive.io/
- Arweave CLI: https://docs.arweave.org/developers/tools/arweave-cli
- Arweave SDK: https://docs.arweave.org/developers/client-sdk/javascript

**Block Explorers**:
- ViewBlock: https://viewblock.io/arweave
- Arweave Explorer: https://explorer.arweave.net/

**Gateways**:
- Arweave.net: https://arweave.net/
- Ar-io.net: https://ar-io.net/

**Related Documents**:
- Wallet setup: `docs/archive/2026-01-03-110600-pst_arweave_wallet_setup_guide.md`
- Cost estimation: `docs/archive/2026-01-03-105500-pst_arweave_cost_estimation.md`
- Execution plan: `docs/archive/2026-01-03-092500-pst_arweave_archive_execution_plan.md`

---

**Date**: 2026-01-03-110700-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **GUIDE READY** — Upload instructions complete

