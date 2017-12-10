git clone --recursive https://github.com/pytorch/pytorch

export CMAKE_PREFIX_PATH="/home/ubuntu/anaconda3/"
/home/ubuntu/anaconda3/bin/conda install pyyaml cmake cffi
/home/ubuntu/anaconda3/bin/conda install -c soumith magma-cuda90

cd pytorch
    /home/ubuntu/anaconda3/bin/python setup.py install