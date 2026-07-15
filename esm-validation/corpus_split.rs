use esm_block_sparse::corpus::generate_disjoint_corpora;
use rand::rngs::StdRng;
use rand::SeedableRng;
use std::collections::HashSet;

fn sentences(text: &str) -> HashSet<&str> {
    text.split_inclusive(". ").collect()
}

#[test]
fn train_and_holdout_sentences_are_unique_and_disjoint() {
    let mut rng = StdRng::seed_from_u64(7);
    let (train, holdout, _) = generate_disjoint_corpora(&mut rng, 400, 80);
    let train_sentences = sentences(&train);
    let holdout_sentences = sentences(&holdout);

    assert_eq!(train_sentences.len(), 400);
    assert_eq!(holdout_sentences.len(), 80);
    assert!(train_sentences.is_disjoint(&holdout_sentences));
}

#[test]
fn split_is_deterministic_and_vocabulary_covers_both_partitions() {
    let mut rng_a = StdRng::seed_from_u64(11);
    let mut rng_b = StdRng::seed_from_u64(11);
    let split_a = generate_disjoint_corpora(&mut rng_a, 40, 12);
    let split_b = generate_disjoint_corpora(&mut rng_b, 40, 12);
    assert_eq!(split_a, split_b);

    let vocabulary: HashSet<char> = split_a.2.iter().copied().collect();
    assert!(split_a
        .0
        .chars()
        .chain(split_a.1.chars())
        .all(|character| vocabulary.contains(&character)));
}
