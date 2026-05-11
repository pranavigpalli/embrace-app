"""Convert best_model_v8.pt to Core ML for on-device inference on iPhone.

Run:  python3 scripts/convert_model.py
Output: EmbraceApp/EmbraceModel.mlpackage

The architecture must match CNNLSTMClassifier defaults in ../models.py:
  input: (1, 600, 8) float32 EMG samples
  output: (1, 6) raw logits (argmax = predicted gesture)
"""

import os
import sys
import torch
import torch.nn as nn

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))
WEIGHTS = os.path.join(PROJECT, "bin", "best_model_v8.pt")
OUT_PATH = os.path.join(HERE, "..", "EmbraceApp", "EmbraceModel.mlpackage")


class CNNLSTMClassifier(nn.Module):
    def __init__(
        self,
        input_size=8,
        num_classes=6,
        conv_channels=(48, 96),
        kernel_size=7,
        lstm_hidden_size=96,
        lstm_num_layers=1,
        dropout=0.25,
        bidirectional=True,
    ):
        super().__init__()
        conv_layers = []
        in_ch = input_size
        for i, out_ch in enumerate(conv_channels):
            conv_layers.extend([
                nn.Conv1d(in_ch, out_ch, kernel_size, padding=kernel_size // 2),
                nn.BatchNorm1d(out_ch),
                nn.ReLU(),
                nn.Dropout(dropout * 0.5),
            ])
            if i == 0:
                conv_layers.append(nn.MaxPool1d(kernel_size=2, stride=2))
            in_ch = out_ch
        self.cnn = nn.Sequential(*conv_layers)
        self.lstm = nn.LSTM(
            input_size=in_ch,
            hidden_size=lstm_hidden_size,
            num_layers=lstm_num_layers,
            batch_first=True,
            dropout=dropout if lstm_num_layers > 1 else 0.0,
            bidirectional=bidirectional,
        )
        out_size = lstm_hidden_size * (2 if bidirectional else 1)
        self.head = nn.Sequential(
            nn.Linear(out_size * 2, 128),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(128, num_classes),
        )

    def forward(self, x):
        # x: (B, T, C) -> (B, C, T)
        x = x.transpose(1, 2)
        x = self.cnn(x)
        x = x.transpose(1, 2)
        lstm_out, _ = self.lstm(x)
        avg_pool = torch.mean(lstm_out, dim=1)
        max_pool, _ = torch.max(lstm_out, dim=1)
        feat = torch.cat([avg_pool, max_pool], dim=1)
        return self.head(feat)


def main():
    try:
        import coremltools as ct
    except ImportError:
        print("ERROR: coremltools not installed. Run:")
        print("  pip3 install coremltools torch")
        sys.exit(1)

    if not os.path.exists(WEIGHTS):
        print(f"ERROR: weights not found at {WEIGHTS}")
        sys.exit(1)

    model = CNNLSTMClassifier()
    state = torch.load(WEIGHTS, map_location="cpu")
    model.load_state_dict(state)
    model.eval()

    dummy = torch.zeros(1, 600, 8, dtype=torch.float32)
    traced = torch.jit.trace(model, dummy)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=(1, 600, 8), dtype=float)],
        outputs=[ct.TensorType(name="logits", dtype=float)],
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.iOS16,
    )

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    mlmodel.save(OUT_PATH)
    print(f"Wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
