#include "Matrix.h"
#include <cmath>

#define SIZE _rows * _columns * sizeof(float)

#define ERRORCHECKF(op) auto err = op; if(err != cudaSuccess) std::cout << cudaGetErrorString(err) << "\n";
#define ERRORCHECK(op) err = op; if(err != cudaSuccess) std::cout << cudaGetErrorString(err) << "\n";

int Matrix::count = 0;

float prec1 = 1000000;

__global__ void setZeros(float* arr, int _rows, int _columns) {
	int i = blockIdx.x;
	int j = threadIdx.x;
	arr[i * _columns + j] = 0;
}

Matrix::Matrix(int rows, int columns) : _rows(rows), _columns(columns) {
	ERRORCHECKF( cudaMalloc(&arr, _rows * _columns * sizeof(float)));
	setZeros <<<_rows, _columns >> > (arr, _rows, _columns);
	cudaDeviceSynchronize();
	float f = sqrt(_columns);
	_blocksForRow = ceil(f);
	_threadsForRow = floor(f) * ceil(f) >= _columns ? f : ceil(f);
}


Matrix::Matrix(const Matrix& other) :Matrix(other._rows, other._columns) {
	//cudaMalloc(&arr, SIZE);
	ERRORCHECKF(cudaMemcpy(arr, other.arr, SIZE, cudaMemcpyDeviceToDevice));
}

Matrix::Matrix(Matrix&& other) {
	arr = other.arr;
	_columns = other._columns;
	_rows = other._rows;
	other.arr = nullptr;
	_blocksForRow = other._blocksForRow;
	_threadsForRow = other._threadsForRow;
}

Matrix::Matrix() :_rows(0), _columns(0) {
}

Matrix& Matrix::operator=(const Matrix& other) {
	ERRORCHECKF(cudaFree(arr));
	ERRORCHECK(cudaMalloc(&arr, SIZE));
	ERRORCHECK(cudaMemcpy(arr, other.arr, SIZE, cudaMemcpyDeviceToDevice));
	
	_blocksForRow = other._blocksForRow;
	_threadsForRow = other._threadsForRow;

	return *this;
}

Matrix::~Matrix() {
	cudaFree(arr);
}

__global__ void cudaGet(int i, int j, float* arr, float* ref, int _rows, int _columns) {
	//cudaMemcpy(ref,&(arr[i * _columns + j]), sizeof(float), cudaMemcpyDeviceToHost);
}

float Matrix::get(int i, int j) const{
	float ref = 0.1f;
	cudaMemcpy(&ref, &(arr[i * _columns + j]), sizeof(float), cudaMemcpyDeviceToHost);
	//cudaGet << <1, 1 >> > (i, j, arr, &ref, _rows, _columns);
	//ERRORCHECKF(cudaDeviceSynchronize());
	return ref;
}

__global__ void cudaSet(int i, int j, float* arr, float value, int _rows, int _columns) {
	arr[i * _columns + j] = value;
}

void Matrix::set(int i, int j, float value) {
	cudaSet << <1, 1 >> > (i, j, arr, value, _rows, _columns);
	cudaDeviceSynchronize();
}

__global__ void addMatrix(float* dst, float* src, int _rows, int _columns) {
	int i = blockIdx.x * _columns + threadIdx.x;
	dst[i] += src[i];
}

Matrix& Matrix::operator+=(const Matrix& other) {
	addMatrix <<<_rows, _columns >>> (arr, other.arr, _rows, _columns);
	cudaDeviceSynchronize();
	return *this;
}

Matrix Matrix::operator+(const Matrix& other) {
	Matrix m (*this);

	return m += other;
}

__global__ void multOnFloat(float* src, float l, int _rows, int _columns) {
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

__global__ void divOnFloat(float* src, float l, int _rows, int _columns) {
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
	_blocksForRow = other._blocksForRow;
	_threadsForRow = other._threadsForRow;
	return *this;
}


__global__ void multRow(float* src, int row, float l, int rows, int columns, int tfr) {
	int i = row * columns + (tfr * blockIdx.x) + threadIdx.x;
	if (i >= row * columns + columns) return;
	//if (src[i] == 0) return;
	//int i = row*columns + threadIdx.x;
	src[i] *= l;
}

void Matrix::MultiplyRow(int row, float l) {
	//std::cout << "columns " << _columns << " blocks " << _blocksForRow << " threads " << _threadsForRow << "\n";
	multRow << <_blocksForRow, _threadsForRow>> > (arr, row, l,_rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();
}

__global__ void plusRows(float* src, int rowDst, int rowSrc, int rows, int columns, int tfr) {
	int i = rowDst * columns + (tfr * blockIdx.x) + threadIdx.x;
	if (i >= rowDst * columns + columns) return;
	int i1 = rowSrc * columns + (tfr * blockIdx.x) + threadIdx.x;
	src[i] += src[i1];
}

void Matrix::PlusRows(int row1, int row2) {
	plusRows << <_blocksForRow, _threadsForRow >> > (arr, row1, row2, _rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();
}

__global__ void minusRows(float* src, int rowDst, int rowSrc, int rows, int columns, int tfr) {
	int i = rowDst * columns + (tfr * blockIdx.x) + threadIdx.x;
	if (i >= rowDst * columns + columns) return;
	int i1 = rowSrc * columns + (tfr * blockIdx.x) + threadIdx.x;
	src[i] -= src[i1];
}

void Matrix::MinusRows(int row1, int row2) {
	minusRows << <_blocksForRow, _threadsForRow >> > (arr, row1, row2, _rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();
}

__global__ void swapRows(float* src, int row1, int row2, int rows, int columns, int tfr) {
	int i = row1 * columns + (tfr * blockIdx.x) + threadIdx.x;
	if (i >= row1 * columns + columns) return;
	int i1 = row2 * columns + (tfr * blockIdx.x) + threadIdx.x;
	float tmp = src[i];
	src[i] = src[i1];
	src[i1] = tmp;
}

void Matrix::swapLines(int line1, int line2) {
	swapRows << <_blocksForRow, _threadsForRow >> > (arr, line1, line2, _rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();
}

__global__ void currentColumnToZero(int current, float* arr, int _rows, int _columns) {
	int i = blockIdx.x + current + 1;
	int j = threadIdx.x + current;
	float f = arr[current * _columns + j];
	f *= arr[i * _columns + current];
	arr[i * _columns + j] -= f;
	if (arr[i * _columns + j] <= 0.000001f) arr[i * _columns + j] = 0;
}

void Matrix::ToUpTriangle() {
	for (int i = 0; i < _rows; ++i) {
		float ii = get(i, i);
		if (ii == 0) continue;
		MultiplyRow(i, 1 / get(i, i));

		//std::cout << "�� ������ ��\n" << std::string(*this) << "\n\n";
		if(i != _rows - 1) currentColumnToZero << <_rows - i - 1, _columns - i >> > (i, arr, _rows, _columns);
		//std::cout << "�� ������ �����\n" << std::string(*this) << "\n\n";
		cudaDeviceSynchronize();
	}
	//std::cout << "blocks " << _blocksForRow << " threads " << _threadsForRow << " columns " << _columns << "\n";
}

__global__ void backMoveFunc(float* x, float* arr, int current, int _rows, int _columns, int ts) {
	int i = blockIdx.x * ts + threadIdx.x;
	if (i >= current) return;
	//int i = threadIdx.x;
	x[i] += x[current] * arr[i * _columns + current];
}

float* Matrix::backMove(){
	float* x_d;
	cudaMalloc(&x_d, sizeof(float) * _rows);
	setZeros << <1, _rows >> > (x_d, _rows, _columns);
	cudaDeviceSynchronize();
	for (int i = _rows - 1; i >= 0; --i) {
		if (i == _rows - 1) {
			cudaSet << <1, 1 >> > (0, i, x_d, get(i, _columns - 1), _rows, _columns);
		}
		else {
			float sum = 0.1f;
			cudaMemcpy(&sum, &(x_d[i]), sizeof(float), cudaMemcpyDeviceToHost);

			//std::cout << i << " col - 1 " << get(i, _columns - 1) << "\n";
			//std::cout << i << " sum " << sum << "\n";

			cudaSet << <1, 1 >> > (0, i, x_d, get(i, _columns - 1) - sum, _rows, _columns);
			cudaDeviceSynchronize();
		}

		if (i != 0) {
			float f = sqrtf(i);
			int blocks = ceil(f);
			int threads = floor(f) * ceil(f) >= i ? f : ceil(f);
			backMoveFunc << <blocks, threads >> > (x_d, arr, i, _rows, _columns, threads);
			cudaDeviceSynchronize();
		}
		//float* xux = new float[_rows];
		//cudaMemcpy(xux, x_d, sizeof(float) * _rows, cudaMemcpyDeviceToHost);
		//for(int g = 0; g < _rows; ++g) std::cout << "x" << g << " = " << xux[g] << " ";
		//std::cout << "\n";
		//delete[] xux;
	}
	float* x = new float[_rows];
	cudaMemcpy(x, x_d, sizeof(float) * _rows, cudaMemcpyDeviceToHost);
	return x;
}

Matrix::operator std::string() const {
	std::string ans = "";

	for (int i = 0; i < _rows; i++) {
		for (int j = 0; j < _columns; ++j)
			ans += std::to_string(get(i,j)) + " ";
		ans += "\n";
	}

	return ans;
}

__global__ void forMult(float* dst, float* arr1, float* arr2, int _rows, int _columns) {
	int  i = blockIdx.x;
	int j = threadIdx.x;
	dst[i * _columns + j] = arr1[i * _columns + i] * arr2[j * _columns + j];
}

Matrix Matrix::Multiply(const Matrix& other) {
	Matrix dst(_rows, _columns);
	forMult <<<_rows, _columns >>> (dst.arr, this->arr, other.arr, _rows, _columns);
	cudaDeviceSynchronize();
	return dst;
}

__global__ void forDiffSquare(float* arr, int current, int _rows, int _columns) {
	int  i = blockIdx.x;
	int j = threadIdx.x;
	if(i != current && j != current)
	arr[i * _columns + j] =0;
}

Matrix Matrix::DiffSquare(int variable) {
	Matrix ret(*this);
	forDiffSquare<<<_rows,_columns>>>(ret.arr, variable, _rows, _columns);
	cudaDeviceSynchronize();

	return ret;
}

__global__ void increm(float* arr, int i, int j, float inc, int _rows, int _columns) {
	arr[i * _columns + j] +=  inc;
}

void Matrix::Increase(int i, int j, float inc){
	increm<<<1, 1 >> > (arr, i, j, inc, _rows, _columns);
	cudaDeviceSynchronize();

}
__global__ void copyDiffToMatrixFunc(float* arr, float* diffArr, int variable, int _rows, int _columns, int tfr) {
	int j = blockIdx.x * tfr + threadIdx.x + 1;
	if (j >= _columns) return;
	arr[(variable - 1) * _columns + j - 1] =
		diffArr[(variable) * _columns + j] + diffArr[(j) * _columns + variable];
}

void Matrix::CopyDiffToMatrix(Matrix& diff, int variable){
	copyDiffToMatrixFunc<<<_blocksForRow, _threadsForRow>>>(arr, diff.arr, variable, _rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();
	set(variable - 1, _columns - 1, -(diff.get(variable, 0) + diff.get(0, variable)));
}

__global__ void writeToDiagFunc(float* dst, float* src, int _rows, int _columns, int tfr) {
	int i = blockIdx.x * tfr + threadIdx.x;
	if (i >= _columns) return;
	dst[i * _columns + i] = src[i];
}

void Matrix::WriteToDiag(float* diagArr){
	float* src;
	cudaMalloc(&src, _columns * sizeof(float));
	cudaMemcpy(src, diagArr, _columns * sizeof(float), cudaMemcpyHostToDevice);
	
	writeToDiagFunc << <_blocksForRow, _threadsForRow >> > (arr, src, _rows, _columns, _threadsForRow);
	cudaDeviceSynchronize();;

	cudaFree(src);
}