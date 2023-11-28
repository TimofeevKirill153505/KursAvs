
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
int getSPcores(cudaDeviceProp devProp)
{
	int cores = 0;
	int mp = devProp.multiProcessorCount;
	switch (devProp.major)
	{
	case 2: // Fermi
		if (devProp.minor == 1) cores = mp * 48;
		else cores = mp * 32;
		break;
	case 3: // Kepler
		cores = mp * 192;
		break;
	case 5: // Maxwell
		cores = mp * 128;
		break;
	case 6: // Pascal
		if (devProp.minor == 1) cores = mp * 128;
		else if (devProp.minor == 0) cores = mp * 64;
		else printf("Unknown device type\n");
		break;
	case 7: // Volta
		if (devProp.minor == 0) cores = mp * 64;
		else printf("Unknown device type\n");
		break;
	default:
		printf("Unknown device type\n");
		break;
	}
	return cores;
}
void print_cuda_device_info(cudaDeviceProp& prop)
{
	printf("Device name:                                        %s\n", prop.name);
	printf("Global memory available on device:                  %zu\n", prop.totalGlobalMem);
	printf("Shared memory available per block:                  %zu\n", prop.sharedMemPerBlock);
	printf("Count of 32-bit registers available per block:      %i\n", prop.regsPerBlock);
	printf("Warp size in threads:                               %i\n", prop.warpSize);
	printf("Maximum pitch in bytes allowed by memory copies:    %zu\n", prop.memPitch);
	printf("Maximum number of threads per block:                %i\n", prop.maxThreadsPerBlock);
	printf("Maximum size of each dimension of a block[0]:       %i\n", prop.maxThreadsDim[0]);
	printf("Maximum size of each dimension of a block[1]:       %i\n", prop.maxThreadsDim[1]);
	printf("Maximum size of each dimension of a block[2]:       %i\n", prop.maxThreadsDim[2]);
	printf("Maximum size of each dimension of a grid[0]:        %i\n", prop.maxGridSize[0]);
	printf("Maximum size of each dimension of a grid[1]:        %i\n", prop.maxGridSize[1]);
	printf("Maximum size of each dimension of a grid[2]:        %i\n", prop.maxGridSize[2]);
	printf("Clock frequency in kilohertz:                       %i\n", prop.clockRate);
	printf("totalConstMem:                                      %zu\n", prop.totalConstMem);
	printf("Major compute capability:                           %i\n", prop.major);
	printf("Minor compute capability:                           %i\n", prop.minor);
	printf("Number of multiprocessors on device:                %i\n", prop.multiProcessorCount);
	printf("Count of cores:                                     %i\n", getSPcores(prop));

	// ...
}

	

__global__ void addVectors(float* a, float* b, float* c, int opPerThread) {
	int base = (blockIdx.x * blockDim.x + threadIdx.x) * opPerThread;
	for (int i = 0; i < opPerThread; ++i) {
		c[i + base] = a[i + base] + b[i + base];
	}
}

void dotest(int threadCount, int arrSize, int blockCount = 1024, int count = 1) {
	//const int arrSize = 10240000;
	//const int blockCount = 1024;
	//const int threadCount = 1000;
	int opPerThread = arrSize / (threadCount * blockCount);
	const int memSize = arrSize * sizeof(float);
	float* a = new float[arrSize];
	float* b = new float[arrSize];
	float* c = new float[arrSize];
	float time = clock();
	for (int i = 0; i < arrSize; ++i)
	{
		a[i] = i * 2.0f;
		b[i] = i * 0.5f;
	}
	cudaError_t er = cudaSetDevice(0);
	if (er != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
	}

	for (int i = 0; i < count; ++i) {
		float* dev_a;
		float* dev_b;
		float* dev_c;

		cudaError_t
			err3 = cudaMalloc(&dev_a, memSize);
		//if (cudaError::cudaSuccess != err3) {
		//	printf_s("Error in malloc dev_a #%i\n", err3);
		//}
		err3 = cudaMalloc(&dev_b, memSize);
		/*if (cudaError::cudaSuccess != err3) {*/
			//	printf_s("Error in malloc dev_b #%i\n", err3);
			//}

		err3 = cudaMalloc(&dev_c, memSize);
		//if (cudaError::cudaSuccess != err3) {
		//	printf_s("Error in malloc dev_с #%i\n", err3);
		//}
		cudaError_t err1 = cudaMemcpy(dev_a, a, memSize, cudaMemcpyHostToDevice);;
		//if (cudaError::cudaSuccess != err1) {
		//	printf_s("Error in memcpy a to device #%i\n", err1);
		//}

		cudaError_t err2 = cudaMemcpy(dev_b, b, memSize, cudaMemcpyHostToDevice);;
		//if (cudaError::cudaSuccess != err2) {
		//	printf_s("Error in memcpy b to device #%i\n", err2);
		//}

		float time = 0;
		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		cudaEventRecord(start, 0);  //Записываем event

		addVectors << <blockCount, threadCount >> > (dev_a, dev_b, dev_c, opPerThread);

		cudaError_t cudaStatus = cudaGetLastError();
		//if (cudaStatus != cudaSuccess) {
		//	fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		//}
		//Создаем event
		cudaStatus = cudaEventRecord(stop, 0);  //Записываем event
		//if (cudaStatus != cudaSuccess) {
		//	fprintf(stderr, "cudaEventRecord returned error code %d\n", cudaStatus);

		//}
		cudaStatus = cudaDeviceSynchronize();
		//if (cudaStatus != cudaSuccess) {
		//	fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);

		//}
		cudaStatus = cudaEventSynchronize(stop);
		/*if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaEventSynchronize returned error code %d after launching addKernel!\n", cudaStatus);

		}*/
		//cudaEventElapsedTime(&time, start, stop);
		//printf_s("threads %i blocks %i arrSize %i time %f", threadCount, blockCount, arrSize, time);
		// Copy output vector from GPU buffer to host memory.
		cudaStatus = cudaMemcpy(c, dev_c, memSize, cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaMemcpy failed! %s\n", cudaGetErrorString(cudaStatus));

		}//Синхронизируем event

		cudaEventElapsedTime(&time, start, stop);
		cudaEventDestroy(start);
		cudaEventDestroy(stop);
		cudaFree(dev_a);
		cudaFree(dev_b);
		cudaFree(dev_c);
		for (int i = 0; i < arrSize; ++i) {
			if (c[i] != i * 2 + i * 0.5f) {
				printf_s("Not match in c[%i] = %f in res = %f\n", i, c[i], i * 2 + i * 0.5f);
				break;
			};
		}
	}

	time -= clock();
	time = -time;
	time /= count;
	delete[] a;
	delete[] b;
	printf_s("Time of compute = %f milliseconds blockCount = %i threadCount = %i arrSize = %i\n", time, blockCount, threadCount, arrSize);

	delete[] c;

	cudaError_t cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
	}
}

int main() {
	
	int threadCount = 1;
	int blockCount = 1;
	int arraySize = 10485760;
	//std::cout << "threadCount, blockCount, arraySize\n";
	//std::cin >> threadCount >> blockCount >> arraySize;
	///*while(threadCount <= 1024){
	//	dotest(threadCount, arraySize);
	//	threadCount *= 2;
	//}*/

	//dotest(threadCount, arraySize, blockCount, 1000);

	//printf_s("\n\n");

	//dotest(5, arraySize);
	////dotest(10, arraySize);
	//printf_s("\n\n");
	//arraySize = 10240000;
	//threadCount = 1;
	//while (threadCount <= 1024) {
	//	dotest(threadCount, arraySize);
	//	threadCount *= 10;
	//}
	//printf_s("\n\n");

	//dotest(8, arraySize);

	//dotest(20, arraySize);
	//dotest(40, arraySize);
	//dotest(80, arraySize);
	//dotest(1000, arraySize, 1000);

	//printf_s("\n\n\n\n\n");
	arraySize = 1000000;
	dotest(1, arraySize, 1000, 1000);
	dotest(1000, arraySize, 1, 1000);
	dotest(1000, arraySize, 1000, 1000);
	float* arr = new float[6]{ 1,2,3,4,5,6 };
	float time = clock();
	for (long long i = 0; i < 1000000000; ++i) {
		arr[i % 6] += arr[(i + 1) % 6];
	}
	time = clock() - time;
	delete[] arr;
	time /= 1000;
	printf_s("Time of compute = %f milliseconds on cpu\n", time);
	/*cudaDeviceProp prop;
	cudaGetDeviceProperties_v2(&prop, 0);
	print_cuda_device_info(prop);*/
}