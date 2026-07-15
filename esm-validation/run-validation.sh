#!/usr/bin/env bash
set -Eeuo pipefail

RESULTS=/tmp/validation-results
SOURCE=/tmp/esm-src
mkdir -p "$RESULTS" "$SOURCE"
exec > >(tee "$RESULTS/validation.log") 2>&1
set -x

cat esm-validation/source.part* | base64 --decode > /tmp/esm-source.tar.gz
gzip --test /tmp/esm-source.tar.gz
tar -xzf /tmp/esm-source.tar.gz -C "$SOURCE"
test -f "$SOURCE/Cargo.toml"
timeout 110s cargo fmt --manifest-path "$SOURCE/Cargo.toml" --all
cat esm-validation/patch64.part* | base64 --decode | gzip --decompress > /tmp/esm-latest.patch
sha256sum /tmp/esm-latest.patch | tee "$RESULTS/remote-patch.sha256"
echo 'c5ffbacefda9a42f5946fd5e90d3de6dcba4ae24d672b4ef14b0a57ab8c4ea1d  /tmp/esm-latest.patch' | sha256sum -c -
wc -c /tmp/esm-latest.patch | tee "$RESULTS/remote-patch.bytes"
git -C "$SOURCE" init -q
git -C "$SOURCE" apply --check /tmp/esm-latest.patch
git -C "$SOURCE" apply /tmp/esm-latest.patch
cp esm-validation/model_invariants.rs "$SOURCE/tests/model_invariants.rs"
cp esm-validation/corpus_split.rs "$SOURCE/tests/corpus_split.rs"
find "$SOURCE" -maxdepth 3 -type f | sort > "$RESULTS/source-manifest.txt"

cd "$SOURCE"
{
  timeout 110s rustc --version
  timeout 110s cargo --version
} 2>&1 | tee "$RESULTS/rust-versions.log"
timeout 110s cargo fetch --locked 2>&1 | tee "$RESULTS/cargo-fetch.log"
timeout 110s cargo fmt --all 2>&1 | tee "$RESULTS/cargo-fmt.log"
timeout 110s cargo fmt --all -- --check 2>&1 | tee -a "$RESULTS/cargo-fmt.log"
tar --exclude=.git --exclude=target --exclude=results -czf "$RESULTS/formatted-source.tar.gz" .
timeout 110s cargo check --all-targets --locked 2>&1 | tee "$RESULTS/cargo-check.log"

for test_name in \
  induction_data corpus_split lm_forward_metadata model_invariants \
  gradient_test_support optimizer_partition attention_ops_grad_check \
  lm_ops_grad_check baseline_grad_check grad_check lm_grad_check; do
  timeout 110s cargo test --locked --test "$test_name" -- --nocapture \
    2>&1 | tee "$RESULTS/test-${test_name}.log"
done

for binary in validated_induction context_baselines v10_separate_optimizer; do
  timeout 110s cargo build --release --locked --bin "$binary" \
    2>&1 | tee "$RESULTS/build-${binary}.log"
done

ESM_STEPS=8 ESM_BATCH=2 ESM_EVAL_SAMPLES=16 ESM_SEED_START=0 ESM_SEED_COUNT=1 \
  ESM_OUTPUT="$RESULTS/induction_seed_0.csv" \
  timeout 110s ./target/release/validated_induction \
  2>"$RESULTS/induction_seed_0_summary.txt"
ESM_STEPS=8 ESM_BATCH=2 ESM_EVAL_SAMPLES=16 ESM_SEED_START=1 ESM_SEED_COUNT=1 \
  ESM_OUTPUT="$RESULTS/induction_seed_1.csv" \
  timeout 110s ./target/release/validated_induction \
  2>"$RESULTS/induction_seed_1_summary.txt"
ESM_EPOCHS=1 ESM_SENTENCES=30 ESM_HOLDOUT_SENTENCES=12 \
  ESM_SEED_START=42 ESM_SEED_COUNT=1 \
  timeout 110s ./target/release/context_baselines \
  >"$RESULTS/context_baselines.csv" \
  2>"$RESULTS/context_baselines_summary.txt"
