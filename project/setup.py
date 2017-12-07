from setuptools import setup, find_packages
from codecs import open
from os import path

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='',
    version='0.0.1',
    description='',
    long_description=long_description,
    url='',
    author='Marcin Elantkowski',
    author_email='marcin.elantkowski@gmail.com',
    license='MIT',
    keywords='',
    packages=find_packages(exclude=['contrib', 'docs', 'tests']),
    install_requires=[],
    package_data={},
    entry_points={
        'console_scripts': [],
    },
)