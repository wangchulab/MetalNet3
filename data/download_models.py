import os
from huggingface_hub import snapshot_download

# Root directory for storing all downloaded protein language models
MODEL_ROOT = "./models"

# List of (local_dir_name, huggingface_repo_id)
# Local dir name follows the original HF repo style (e.g. esm2_t30_150M_UR50D)
plm_list = [
    ("esm2_t12_35M_UR50D",    "facebook/esm2_t12_35M_UR50D"),
    ("esm2_t30_150M_UR50D",   "facebook/esm2_t30_150M_UR50D"),
    ("esm2_t33_650M_UR50D",   "facebook/esm2_t33_650M_UR50D"),
    ("esm2_t36_3B_UR50D",     "facebook/esm2_t36_3B_UR50D"),

    ("SaProt_650M_AF2",       "westlake-repl/SaProt_650M_AF2"),
    ("SaProt_650M_PDB",       "westlake-repl/SaProt_650M_PDB"),

    ("ProSST-2048",           "AI4Protein/ProSST-2048"),

    ("prot_t5_xl_uniref50",   "Rostlab/prot_t5_xl_uniref50"),

    ("ankh-base",             "ElnaggarLab/ankh-base"),
    ("ankh-large",            "ElnaggarLab/ankh-large"),
]

for local_name, repo_id in plm_list:
    local_dir = os.path.join(MODEL_ROOT, local_name)

    print(f"\n>>> Downloading {repo_id} -> {local_dir}")

    # Download the full repo snapshot to local_dir
    # resume_download=True: supports resuming after interruption
    # local_dir_use_symlinks=False: store real files, no symlinks (better for cluster/container)
    snapshot_download(
        repo_id=repo_id,
        repo_type="model",
        local_dir=local_dir,
        local_dir_use_symlinks=False,
        resume_download=True,
    )

    print(f">>> Done: {local_dir}")

print("\n✅ All PLMs downloaded successfully.")
