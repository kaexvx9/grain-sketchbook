#!/bin/bash
# Why: Generate current timestamp in yyyy-mm-dd-hhmmss-pst format for headers and filename prefixes.
# Usage: ./generate-timestamp.sh
# Output: yyyy-mm-dd-hhmmss-pst (e.g., 2026-01-23-160603-pst)
# Note: For versioning, use Rye Style chronological format: YYYYMMDD.HHMMSS.variant

date +"%Y-%m-%d-%H%M%S-pst"
