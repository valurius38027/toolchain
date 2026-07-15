use esm_block_sparse::autodiff::Arr;
use esm_block_sparse::lm::{LmHyperParams, LmModel};
use esm_block_sparse::model::{HyperParams, Model};
use ndarray::Array2;

fn model_hyperparams() -> HyperParams {
    HyperParams {
        d_model: 6,
        block_hidden: 5,
        num_blocks: 4,
        top_k: 2,
        num_layers: 2,
        g_dim: 4,
        value_hidden: 4,
        signal_dim: 2,
        lambda: 0.8,
        independent_subspace: false,
        use_feedback: false,
        gated_feedback: false,
    }
}

fn lm_hyperparams() -> LmHyperParams {
    LmHyperParams {
        vocab_size: 8,
        d_model: 6,
        block_hidden: 5,
        num_blocks: 4,
        top_k: 2,
        num_layers: 2,
        g_dim: 4,
        lambda: 0.8,
        independent_subspace: false,
        use_feedback: false,
        gated_feedback: false,
        use_retrieval: false,
        retrieval_window: 0,
        d_key: 3,
    }
}

#[test]
#[should_panic(expected = "num_layers must be positive")]
fn synthetic_model_rejects_zero_layers_before_subspace_arithmetic() {
    let mut hp = model_hyperparams();
    hp.num_layers = 0;
    hp.independent_subspace = true;
    let _ = Model::new(hp, 1);
}

#[test]
#[should_panic(expected = "top_k must be in 1..=num_blocks")]
fn synthetic_model_rejects_oversized_top_k() {
    let mut hp = model_hyperparams();
    hp.top_k = hp.num_blocks + 1;
    let _ = Model::new(hp, 1);
}

#[test]
#[should_panic(expected = "gated_feedback requires use_feedback")]
fn synthetic_model_rejects_disconnected_gate() {
    let mut hp = model_hyperparams();
    hp.gated_feedback = true;
    let _ = Model::new(hp, 1);
}

#[test]
#[should_panic(expected = "forced routing schedule length must match input length")]
fn synthetic_model_rejects_short_forced_schedule() {
    let model = Model::new(model_hyperparams(), 1);
    let inputs: Vec<Arr> = vec![Array2::zeros((1, 6)), Array2::zeros((1, 6))];
    let schedule = vec![vec![0, 1]];
    let _ = model.forward_sequence(&inputs, None, Some(&schedule));
}

#[test]
#[should_panic(expected = "forced top-k indices must be unique")]
fn synthetic_model_rejects_duplicate_forced_experts() {
    let model = Model::new(model_hyperparams(), 1);
    let inputs: Vec<Arr> = vec![Array2::zeros((1, 6))];
    let schedule = vec![vec![1, 1]];
    let _ = model.forward_sequence(&inputs, None, Some(&schedule));
}

#[test]
#[should_panic(expected = "gated_feedback requires use_feedback")]
fn language_model_rejects_disconnected_gate() {
    let mut hp = lm_hyperparams();
    hp.gated_feedback = true;
    let _ = LmModel::new(hp, 1);
}

#[test]
#[should_panic(expected = "token id out of vocabulary")]
fn language_model_rejects_out_of_range_tokens() {
    let model = LmModel::new(lm_hyperparams(), 1);
    let _ = model.forward_sequence(&[0, 8]);
}
