#!/usr/bin/env bash
set -Eeuo pipefail

RESULTS=/tmp/experiment-results
SOURCE=/tmp/esm-src
mkdir -p "$RESULTS" "$SOURCE"
exec > >(tee "$RESULTS/runner.log") 2>&1
set -x

cat esm-validation/source.part* | base64 --decode > /tmp/esm-source.tar.gz
gzip --test /tmp/esm-source.tar.gz
tar -xzf /tmp/esm-source.tar.gz -C "$SOURCE"
timeout 110s cargo fmt --manifest-path "$SOURCE/Cargo.toml" --all
cat esm-validation/patch64.part* | base64 --decode | gzip --decompress > /tmp/esm-latest.patch
echo 'c5ffbacefda9a42f5946fd5e90d3de6dcba4ae24d672b4ef14b0a57ab8c4ea1d  /tmp/esm-latest.patch' | sha256sum -c -
git -C "$SOURCE" init -q
git -C "$SOURCE" apply --check /tmp/esm-latest.patch
git -C "$SOURCE" apply /tmp/esm-latest.patch
cp esm-validation/model_invariants.rs "$SOURCE/tests/model_invariants.rs"
cp esm-validation/corpus_split.rs "$SOURCE/tests/corpus_split.rs"

cd "$SOURCE"
{
  timeout 110s rustc --version
  timeout 110s cargo --version
} > "$RESULTS/rust-versions.log" 2>&1

case "${EXPERIMENT:?EXPERIMENT is required}" in
  induction)
    timeout 110s cargo build --release --locked --bin validated_induction \
      > "$RESULTS/build.log" 2>&1
    ESM_STEPS="${ESM_STEPS:-600}" \
    ESM_BATCH="${ESM_BATCH:-4}" \
    ESM_EVAL_SAMPLES="${ESM_EVAL_SAMPLES:-96}" \
    ESM_SEED_START="${SEED_START:?SEED_START is required}" \
    ESM_SEED_COUNT="${SEED_COUNT:?SEED_COUNT is required}" \
    ESM_OUTPUT="$RESULTS/induction.csv" \
      timeout 110s ./target/release/validated_induction \
      2> "$RESULTS/summary.txt"
    ;;
  context)
    timeout 110s cargo build --release --locked --bin context_baselines \
      > "$RESULTS/build.log" 2>&1
    ESM_EPOCHS="${ESM_EPOCHS:-3}" \
    ESM_SENTENCES="${ESM_SENTENCES:-80}" \
    ESM_HOLDOUT_SENTENCES="${ESM_HOLDOUT_SENTENCES:-24}" \
    ESM_DATA_SEED="${ESM_DATA_SEED:-7}" \
    ESM_SEED_START="${SEED_START:?SEED_START is required}" \
    ESM_SEED_COUNT="${SEED_COUNT:?SEED_COUNT is required}" \
      timeout 110s ./target/release/context_baselines \
      > "$RESULTS/context.csv" \
      2> "$RESULTS/summary.txt"
    ;;
  *)
    echo "unknown experiment: $EXPERIMENT" >&2
    exit 2
    ;;
esac
