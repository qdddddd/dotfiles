#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Make sure the following packages are install before file execution:
numpy
tensorflow-gpu
numba
cudatoolkit
"""

import sys
import tensorflow as tf

import numpy as np
from timeit import default_timer as timer
from numba import vectorize

# This should be a substantially high value. On my test machine, this took
# 33 seconds to run via the CPU and just over 3 seconds on the GPU.
NUM_ELEMENTS = 10000000


# This is the CPU version.
def vector_add_cpu(a, b):
    c = np.zeros(NUM_ELEMENTS, dtype=np.float32)
    for i in range(NUM_ELEMENTS):
        c[i] = a[i] + b[i]
    return c


# This is the GPU version. Note the @vectorize decorator. This tells
# numba to turn this into a GPU vectorized function.
@vectorize(["float32(float32, float32)"], target='cuda')
def vector_add_gpu(a, b):
    return a + b


def main():
    a_source = np.ones(NUM_ELEMENTS, dtype=np.float32)
    b_source = np.ones(NUM_ELEMENTS, dtype=np.float32)

    # Time the CPU function
    start = timer()
    vector_add_cpu(a_source, b_source)
    vector_add_cpu_time = timer() - start

    # Time the GPU function
    start = timer()
    vector_add_gpu(a_source, b_source)
    vector_add_gpu_time = timer() - start

    # Report times
    print("CPU function took %f seconds." % vector_add_cpu_time)
    print("GPU function took %f seconds." % vector_add_gpu_time)

    return 0

if __name__ == "__main__":
    print(sys.version)
    print("\n=================================\n")
    tf.debugging.set_log_device_placement(True)

    gpus = tf.config.experimental.list_physical_devices("GPU");
    print(gpus)
    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, enable=True)

    for i in range(len(gpus)):
        with tf.device("/GPU:" + str(i)):
            a = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[2, 3], name='a')
            b = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[3, 2], name='b')
            c = tf.matmul(a, b)
            print(c)
    print("Tensorflow installed properly !!\n")

    print("Start comparing CPU and GPU ...\n")
    main()
    print("============== the end =====================\n")
