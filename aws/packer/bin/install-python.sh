#!/usr/bin/env bash

set -e

CONDA_FILE="Anaconda3-5.0.1-Linux-x86_64.sh"
wget https://repo.continuum.io/archive/${CONDA_FILE}
bash ${CONDA_FILE} -b
rm   ${CONDA_FILE}

echo "export PATH=/home/ubuntu/anaconda3/bin:$PATH" >> ~/.bashrc

/home/ubuntu/anaconda3/bin/pip   install -r /home/ubuntu/local-setup/requirements.txt
/home/ubuntu/anaconda3/bin/conda install -y --file /home/ubuntu/local-setup/conda-list.txt

/home/ubuntu/anaconda3/bin/python -m spacy download en
