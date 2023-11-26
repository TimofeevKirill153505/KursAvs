#include "Matrix.h"
#include <cmath>

#define SIZE _rows * _columns * sizeof(float)

int Matrix::count = 0;

float prec1 = 1000000;

Matrix::Matrix(int rows, int columns) : _rows(rows), _columns(columns) {
	cudaMalloc(&arr, _rows * _columns * sizeof(float));
}

__global__ void copyFunc(float* dst, float* src) {

}

Matrix::Matrix(const Matrix& other) :Matrix(other._rows, other._columns) {
	cudaMemcpy(arr, other.arr, SIZE, cudaMemcpyDeviceToDevice);
}

Matrix::Matrix(Matrix&& other) {
	arr = other.arr;
	_columns = other._columns;
	_rows = other._rows;
	other.arr = nullptr;
}

Matrix::Matrix() :_rows(0), _columns(0) {
}

Matrix& Matrix::operator=(const Matrix& other) {
	cudaFree(arr);
	cudaMalloc(&arr, SIZE);
	cudaMemcpy(arr, other.arr, SIZE, cudaMemcpyDeviceToDevice);
}

Matrix::~Matrix() {
	cudaFree(arr);
}

__device__ void addMatrix(float* dst, float* src, int _rows, int _columns) {
	int i = blockIdx.x * _columns + threadIdx.x;
	dst[i] += src[i];
}

Matrix& Matrix::operator+=(const Matrix& other) {
	addMatrix <<<_rows, _columns >>> (arr, other._arr, _rows, _columns);
	cudaDeviceSynchronize();
	return *this;
}

Matrix Matrix::operator+(const Matrix& other) {
	Matrix m (*this);

	return m += other;
}

__device__ void multOnFloat(float* src, float l, int _rows, int _columns) {
	src[blockIdx.x * _columns + threadIdx.x] *= l;
}

Matrix& Matrix::operator*=(float l) {
	multOnFloat<<<_rows, _columns>>>(arr, l, _rows, _columns);
	cudaDeviceSynchronize();
	return* this;
}

Matrix Matrix::operator*(float l) {
	Matrix m(*this);

	return m *= l;
}

__device__ void divOnFloat(float* src, float l, int _rows, int _columns) {
	src[blockIdx.x * _columns + threadIdx.x] /= l;
}

Matrix& Matrix::operator/=(float l) {
	divOnFloat <<<_rows, _columns >>> (arr, l, _rows, _columns);
	cudaDeviceSynchronize();
	return*this;
}

Matrix Matrix::operator/(float l) {
	Matrix m(*this);

	return m /= l;
}

Matrix& Matrix::operator=(Matrix&& other) {
	cudaFree(arr);
	arr = other.arr;
	_columns = other._columns;
	_rows = other._rows;
	other.arr = nullptr;
}


__global__ void multRow(float* src, int row, float l, int rows, int columns) {
	int i = row * columns + threadIdx.x;
	src[i] *= l;
}

void Matrix::MultiplyRow(int row, float l) {
	multRow << <1, _columns >> > (arr, row, l,_rows, _columns);
	cudaDeviceSynchronize();
}

__global__ void plusRows(float* src, int rowDst, int rowSrc, int rows, int columns) {
	int i = rowDst * columns + threadIdx.x;
	int i1 = rowSrc * columns + threadIdx.x;
	src[i] += src[i1];
}

void Matrix::PlusRows(int row1, int row2) {
	plusRows << <1, _columns >> > (arr, row1, row2, _rows, _columns);
	cudaDeviceSynchronize();
}

__global__ void minusRows(float* src, int rowDst, int rowSrc, int rows, int columns) {
	int i = rowDst * columns + threadIdx.x;
	int i1 = rowSrc * columns + threadIdx.x;
	src[i] -= src[i1];
}

void Matrix::MinusRows(int row1, int row2) {
	minusRows << <1, _columns >> > (arr, row1, row2, _rows, _columns);
	cudaDeviceSynchronize();
}

__global__ void swapRows(float* src, int row1, int row2, int rows, int columns) {
	int i = row1 * columns + threadIdx.x;
	int i1 = row2 * columns + threadIdx.x;
	float tmp = src[i];
	src[i] = src[i1];
	src[i1] = tmp;
}

void Matrix::swapLines(int line1, int line2) {
	swapRows << <1, _columns >> > (arr, row1, row2, _rows, _columns);
	cudaDeviceSynchronize();
}

void Matrix::ToUpTriangle() {
	int min = _rows < _columns ? _rows : _columns;

	for (int i = 0; i < min; ++i) {
		if (arr[i, i] == 0) break;

		int maxRow = i;
		for (int j = i + 1; j < _rows; ++j)
			if (arr[j, i] > arr[maxRow, i] && arr[j, i] != 0) maxRow = j;
		swapLines(i, maxRow);


		MultiplyRow(i, 1 / arr[i][i]);
		for (int j = i + 1; j < _rows; ++j) {
			float c = arr[j][i];
			if (c == 0) continue;

			MultiplyRow(i, c);
			MinusRows(j, i);
			MultiplyRow(i, 1 / c);

		}
	}
}

Matrix::operator std::string() const {
	std::string ans = "";

	for (int i = 0; i < _rows; i++) {
		for (int j = 0; j < _columns; ++j)
			ans += std::to_string((floorf(arr[i][j] * prec1) / prec1)) + " ";
		ans += "\n";
	}

	return ans;
}
