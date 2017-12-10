#!/usr/bin/env bash

set -e

/home/ubuntu/anaconda3/bin/python -c "import os ; import torch ; print('CUDA OK') if torch.cuda.is_available() else os.abort()"
/home/ubuntu/anaconda3/bin/python -c "import torch ; x = torch.randn(3,3).cuda() ; x += x; print('CUDA MATH OK')"