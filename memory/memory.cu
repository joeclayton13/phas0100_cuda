/*
 * An exercise on the different types of memory available in CUDA
 */

#include <iostream>
#include <cstdlib>

// Error checking macro function
#define myCudaCheck(result) { cudaErrorCheck((result), __FILE__, __LINE__); }
inline void cudaErrorCheck(cudaError_t err, const char* file, int line)
{
  if (err != cudaSuccess) {
    std::cerr << "CUDA error: " << cudaGetErrorString(err) << " at " << file << ":" << line << std::endl;
    exit(err);
  }
}

// Array size
// HANDSON 2.1 Change the array size to a static __constant__ int
//#define ARRAY_SIZE 65536
static __constant__ int arraysize; 

// CUDA threads per block
#define nThreads 128

// Array reversing kernel
__global__
void reverse(float* devA, float* devB)
{
  // HANDSON 2.3 Create a __shared__ temporary array of length nThreads for the swap
  __shared__ float temp[nThreads];

  // Get the index in this block
  int idx = blockIdx.x * blockDim.x + threadIdx.x;

  // HANDSON 2.4 Fill the temporary array
  temp[nThreads - (threadIdx.x + 1)] = devA[idx];

  // HANDSON 2.5 synchronize the threads
  __syncthreads(); 

  // HANDSON 2.6 Calculate the initial position of this block in the grid
  int blockOffset = arraysize - (blockIdx.x + 1) * blockDim.x;

  // HANDSON 2.7 Fill the output array with the reversed elements from this block
  devB[blockOffset + threadIdx.x] = temp[threadIdx.x];
}

// Main host function
int main( )
{
  // HANDSON 2.2 Replace the host array size by a const int
  const int host_arraysize = 65536;
  // size of the array in char
  size_t sizeChar = host_arraysize * sizeof(float);

  // Allocate host memory
  float* hostIn = (float*) malloc(sizeChar);
  float* hostOut = (float*) malloc(sizeChar);

  // Allocate device memory
  float* devIn;
  float* devOut;
  myCudaCheck(
	      cudaMalloc(&devIn, sizeChar)
	      );
  myCudaCheck(
	      cudaMalloc(&devOut, sizeChar)
	      );

  // Initialize the arrays
  for (int i = 0; i < host_arraysize; i++) {
    hostIn[i] = i;
    hostOut[i] = 0;
  }

  // Copy the input array from the host to the device
  myCudaCheck(
	      cudaMemcpy(devIn, hostIn, sizeChar, cudaMemcpyHostToDevice)
	      );

  // Define the size of the task
  dim3 blocksPerGrid(host_arraysize/nThreads);
  dim3 threadsPerBlock(nThreads);

  reverse<<<blocksPerGrid, threadsPerBlock>>>(devIn, devOut);

  // Wait for all threads to complete
  myCudaCheck(
	      cudaDeviceSynchronize()
	      );

  // Copy the result array back to the host
  myCudaCheck(
	      cudaMemcpy(hostOut, devOut, sizeChar, cudaMemcpyDeviceToHost)
	      );

  // Check and print the result
  int nCorrect = 0;
  for (int i = 0; i < host_arraysize; i++) {
    nCorrect += (hostOut[i] == hostIn[host_arraysize - (i+1)]) ? 1 : 0;
  }
  std::cout << ((nCorrect == host_arraysize) ? "Success! " : "Failure: ");
  std::cout << nCorrect  << " elements were correctly swapped." << std::endl;

  // Free device memory
  myCudaCheck(
	      cudaFree(devIn)
	      );
  myCudaCheck(
	      cudaFree(devOut)
	      );

  // Free host memory
  free(hostIn);
  free(hostOut);

  return 0;
}