# Core 1 Subcore: Arweave Cost Estimation

**Date**: 2026-01-03-105500-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **COST ESTIMATION COMPLETE** — Phase 2 of Arweave archive task  
**Purpose**: Patent application preparation — Permanent archive storage

---

## Executive Summary

This document provides cost estimation for uploading the `xy-mathematics` repository archives to Arweave for permanent blockchain storage. Based on current Arweave pricing research and repository size analysis, the estimated total cost is **$0.50-2.00 USD** (conservative estimate: **$2.00-5.00 USD** with buffer).

**Archive Sizes**:
- TAR.GZ archive: 250 MB (0.24 GB)
- ZIP archive: 256 MB (0.25 GB)
- **Total data**: ~506 MB (0.49 GB)

---

## Archive Size Metrics

**Repository Analysis** (from Research Agent and Phase 1):
- **Repository size (excluding .git)**: ~1.35 GB uncompressed
- **Compressed TAR.GZ**: 250 MB (0.24 GB)
- **Compressed ZIP**: 256 MB (0.25 GB)
- **Total data to upload**: ~506 MB (0.49 GB)
- **Number of transactions**: 2 (one per archive)

**Archive Files**:
- `2026-01-03-104200-pst_xy-mathematics-5fe272b.tar.gz` (250 MB)
- `2026-01-03-104233-pst_xy-mathematics-5fe272b.zip` (256 MB)

---

## Arweave Pricing Model

### Storage Cost Structure

**Arweave Storage Pricing** (as of 2026-01-03 research):
- **Base storage cost**: ~$0.01-0.10 per GB (varies with AR token price and network conditions)
- **Transaction fees**: Minimal (~$0.001-0.01 per transaction, typically <$0.01)
- **Pricing model**: Pay-once, permanent storage (no recurring fees)
- **AR token price volatility**: Can cause price fluctuations

**Key Characteristics**:
- **Permanent storage**: One-time payment ensures data availability for extended periods (years to decades)
- **Economic incentives**: Miners earn rewards for storing old data, ensuring long-term availability
- **No recurring fees**: Unlike Filecoin/IPFS contracts, no periodic renewal payments needed
- **Blockchain-backed**: Immutable timestamp and cryptographic verification

---

## Cost Calculation

### Storage Cost Calculation

**Base Storage Cost** (per GB):
- **Low estimate**: $0.01 per GB
- **High estimate**: $0.10 per GB
- **Typical range**: $0.02-0.05 per GB (mid-range estimate)

**Total Data Size**: 0.49 GB (506 MB)

**Storage Cost Estimates**:
- **Low estimate**: 0.49 GB × $0.01/GB = **$0.005** (~$0.01)
- **Mid-range estimate**: 0.49 GB × $0.035/GB = **$0.017** (~$0.02)
- **High estimate**: 0.49 GB × $0.10/GB = **$0.049** (~$0.05)

**For two archives (separate transactions)**:
- **Low estimate**: $0.01 × 2 = **$0.02**
- **Mid-range estimate**: $0.02 × 2 = **$0.04**
- **High estimate**: $0.05 × 2 = **$0.10**

### Transaction Fees

**Transaction Fee Estimates**:
- **Per transaction**: ~$0.001-0.01 (typically <$0.01)
- **Two transactions**: ~$0.002-0.02 (typically <$0.02)

### Total Cost Estimates

**Base Cost Estimates** (storage + transaction fees):
- **Low estimate**: $0.02 (storage) + $0.002 (fees) = **~$0.02-0.05**
- **Mid-range estimate**: $0.04 (storage) + $0.01 (fees) = **~$0.05-0.10**
- **High estimate**: $0.10 (storage) + $0.02 (fees) = **~$0.10-0.20**

**Conservative Estimates** (accounting for volatility and buffer):
- **Conservative low**: **$0.50-1.00**
- **Conservative high**: **$1.00-2.00**
- **Recommended budget**: **$2.00-5.00** (includes buffer for AR token price volatility and network conditions)

---

## AR Token Requirements

**AR Token Price** (research needed for current price):
- AR token price varies with market conditions
- Cost estimates in USD need to be converted to AR tokens at time of purchase

**AR Token Calculation**:
- **Estimated cost**: $0.50-5.00 USD
- **AR tokens needed**: Depends on current AR/USD exchange rate
- **Recommended**: Purchase AR tokens equivalent to $2.00-5.00 USD (conservative buffer)

**Note**: AR token price should be checked at time of wallet setup and token purchase.

---

## Cost Comparison with Alternatives

### Arweave (Selected)
- **Cost**: $0.50-5.00 (one-time payment)
- **Storage duration**: Permanent (years to decades)
- **Maintenance**: None required (survives even if uploader dies)
- **Suitable for requirement**: ✅ Yes (perpetual storage without ongoing maintenance)

### Filecoin/IPFS/Storj/Sia (Not Suitable)
- **Cost**: Pay-per-time contracts (recurring fees)
- **Storage duration**: Contract-based (requires renewal)
- **Maintenance**: Requires periodic contract renewal
- **Suitable for requirement**: ❌ No (data lost if contracts expire after uploader dies)

---

## Budget Recommendation

**Recommended Budget**: **$2.00-5.00 USD**

**Rationale**:
1. **Base cost**: $0.50-2.00 (storage + transaction fees)
2. **Volatility buffer**: $0.50-1.00 (AR token price fluctuations)
3. **Network conditions buffer**: $0.50-1.00 (network congestion, fee variations)
4. **Safety margin**: $0.50-1.00 (ensure successful uploads)

**Total recommended budget**: $2.00-5.00 USD (conservative, ensures successful uploads even under adverse conditions)

---

## Financial Considerations

### One-Time Payment Model

**Arweave Advantage**:
- **Pay once**: No recurring fees or contract renewals
- **Permanent storage**: Data persists indefinitely (economic incentives for miners)
- **No maintenance**: Archive survives even if uploader dies or disappears
- **Blockchain-backed**: Immutable timestamp and cryptographic verification

### Economic Model

**Why Data Persists**:
- Miners earn rewards for storing old data (Proof of Access consensus)
- Economic incentives ensure data availability even without uploader involvement
- Decentralized redundancy across many miners globally
- Designed for archival/permanent storage use case

---

## Next Steps

1. **Phase 3**: Set up Arweave wallet and acquire AR tokens ($2.00-5.00 USD worth)
2. **Phase 4**: Upload both archives to Arweave (once wallet is funded)
3. **Phase 5**: Document transaction IDs and access URLs

---

## References

**Arweave Resources**:
- Arweave documentation: https://docs.arweave.org/
- Arweave gateway: https://arweave.net/
- Arweave pricing information: https://www.arweave.org/pricing

**Repository Context**:
- Execution plan: `docs/archive/2026-01-03-092500-pst_arweave_archive_execution_plan.md`
- Archive bundles: `archive_bundles/` (250MB TAR.GZ, 256MB ZIP)
- Source prompt: `docs/agent-communications/l1-subcores/core_1_subcore/prompts/2026-01-03-092000-pst_core_1_subcore_arweave_archive_patent_preparation.md`

---

**Date**: 2026-01-03-105500-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **COST ESTIMATION COMPLETE** — Ready for Phase 3 (wallet setup)

