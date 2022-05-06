/*#include "nbody.cuh"
#define ITERS 100

int main(int argc, char** argv){
  cudaEvent_t start, stop;
  float elapsedTime;
  initCUDA();
  cudaEventCreate(&start);
  cudaEventRecord(start,0);

  // execute kernel
  for (int j = 0; j < ITERS; j++)
      runKernelNBodySimulation();

 cudaThreadSynchronize();
 cudaEventCreate(&stop);
 cudaEventRecord(stop,0);
 cudaEventSynchronize(stop);

 cudaEventElapsedTime(&elapsedTime, start,stop);
 printf("Running %d kernels\n", ITERS);
 printf("Elapsed time : %f ms\n" ,elapsedTime);

  double dSeconds = elapsedTime/(1000.0);

  double gflops = BODIES * BODIES/dSeconds/1.0e9 * ITERS ;

  printf("Throughput: %f GFLOPS\n" ,gflops);
 cudaThreadExit();
}
*/