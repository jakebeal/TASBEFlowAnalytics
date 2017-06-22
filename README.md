This is the TASBE Flow Analytics package, release 1.0.0-alpha

This project is intended to be run using either Matlab or Octave.
To use the package, you should either add it to your path, e.g.:

    addpath('path to package');

In use of this package, you will typically want to split your
processing into three stages:

- Creation of a ColorModel that translates raw FCS to comparable unit data
- Using a ColorModel for batch processing of experimental data
- Comparison and plotting of the results of batch processing

Example files are provided that show how these stages typically work.
