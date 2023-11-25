#include "Matrix.h"
#include <cmath>

int Matrix::count = 0;

float prec1 = 1000000;
int threadCount = 0;

Matrix::Matrix(int rows, int columns) : _rows(rows), _columns(columns) {
	id = count;
	++count;
	arr = new float* [_rows];
	for (int i = 0; i < _rows; ++i) {
		arr[i] = new float[_columns];
		for (int j = 0; j < _columns; ++j)
			arr[i][j] = 0;
	}
}

Matrix::Matrix(const Matrix& other) :Matrix(other._rows, other._columns) {
	//std::cout << "def copy constructor from " << other.id << " to " << id << "\n";
	for (int i = 0; i < other._rows; ++i) {
		for (int j = 0; j < other._columns; ++j) {
			arr[i][j] = other.arr[i][j];
		}
	}
}

Matrix::Matrix(Matrix&& other) {
	id = count;
	//std::cout << "rv copy constructor from " << other.id << " to " << id << "\n";
	++count;
	arr = other.arr;
	_columns = other._columns;
	_rows = other._rows;
	other.arr = nullptr;
}

Matrix::Matrix() :_rows(0), _columns(0) {
	id = count;
	++count;
	arr = nullptr;
}

Matrix& Matrix::operator=(const Matrix& other) {
	//std::cout << "def copy operator from " << other.id << " to " << id << "\n";
	for (int i = 0; i < _rows; ++i) {
		delete[] arr[i];
	}
	delete[] arr;

	_rows = other._rows;
	_columns = other._columns;

	arr = new float* [_rows];
	for (int i = 0; i < _rows; ++i) {
		arr[i] = new float[_columns];
		for (int j = 0; j < _columns; ++j)
			arr[i][j] = other.arr[i][j];
	}

	return *this;
}

Matrix::~Matrix() {
	//std::cout << "deleting matrix " << id << "\n";
	if (arr == nullptr) return;
	for (int i = 0; i < _rows; ++i) {
		delete[] arr[i];
	}
	delete[] arr;
}

Matrix& Matrix::operator+=(const Matrix& other) {

	//std::cout << "this BEFORE adding\n" << std::string(*this) << "\n";
	auto lambda = [this, other](const Matrix* const other, int begi, int endi, int begj, int endj) {
		for (int i = begi; i < endi; ++i) {
			for (int j = begj; j < endj; ++j) {
				arr[i][j] += other->arr[i][j];
			}
		}
	};

	//AAAA
	//std::thread a(lambda, &other, 0, _rows / 2, 0, _columns);

	//lambda(& other, _rows / 2, _rows, 0, _columns);

	std::thread a(lambda, &other, 0, _rows / 2, 0, _columns / 2);
	std::thread b(lambda, &other, 0, _rows / 2, _columns / 2, _columns); 
	std::thread c(lambda, &other, _rows / 2, _rows, 0, _columns / 2);
	lambda(&other, _rows / 2, _rows, _columns / 2, _columns);
	//threadCount += 4;
	//std::cout << "Запущено " << threadCount << " потока для суммирования матриц" << "\n";
	a.join();
	b.join();
	c.join();
	//d.join();*/
	//threadCount -= 4;
	//std::cout << "Закончено " << 4 << " потока для суммирования матриц" << "\n";
	//std::cout << "this AFTER adding\n" << std::string(*this) << "\n";
	//int g = 0;
	//++g;
	return *this;

}

Matrix Matrix::operator+(const Matrix& other) {
	Matrix ret(*this);

	return ret += other;
}
//
//Matrix& Matrix::operator=*(const Matrix& other) {
//	Matrix matrixNew = Matrix(_rows, other._columns);
//	for (int i = 0; i < matrixNew._rows; ++i)
//		for (int j = 0; j < matrixNew._columns; ++j)
//			for (int r = 0; r < _columns; ++r)
//				matrixNew.arr[i][j] += arr[i][r] * other.arr[r][j];
//	return matrixNew;
//}

Matrix& Matrix::operator*=(float l) {
	///AAAA
	auto lambda = [this, l](int begi, int endi) {
		for (int i = begi; i < endi; ++i) {
			for (int j = 0; j < _columns; ++j) {
				arr[i][j] *= l;;
			}
		}
	};

	std::thread a(lambda, 0, _rows / 2);
	lambda(_rows/2, _rows);
	a.join();
	return *this;
}

Matrix Matrix::operator*(float l) {
	Matrix ret(*this);
	return ret *= l;
}

Matrix& Matrix::operator/=(float l) {
	//AAAA
	auto lambda = [this, l](int begi, int endi) {
		for (int i = begi; i < endi; ++i) {
			for (int j = 0; j < _columns; ++j) {
				arr[i][j] /= l;
			}
		}
		};

	std::thread a(lambda, 0, _rows / 2);
	lambda(_rows / 2, _rows);
	a.join();

	return *this;
}

Matrix Matrix::operator/(float l) {
	Matrix ret(*this);
	return ret /= l;
}

Matrix& Matrix::operator=(Matrix&& other) {
	//std::cout << "rv copy operator from " << other.id << " to " << id << "\n";
	int i = 0;
	int j = 0;
	delete[] arr;
	arr = other.arr;
	arr[i][i] = arr[j][j];
	_columns = other._columns;
	_rows = other._rows;
	other.arr = nullptr;

	return *this;
}


void Matrix::MultiplyRow(int row, float l) {
	auto lambda = [this, row, l](int beg, int endj) {
		for (int j = beg; j < endj; ++j) {
			arr[row][j] *= l;
		}
	};

	//std::thread a(lambda, 0, _columns / 2);
	lambda(0, _columns);
	//a.join();
}

void Matrix::PlusRows(int row1, int row2) {
	auto lambda = [this, row1, row2](int beg, int endj) {
		for (int j = beg; j < endj; ++j) {
			arr[row1][j] += arr[row2][j];

		}
	};

	//std::thread a(lambda, 0, _columns / 2);
	lambda(0, _columns);
	//a.join();
}

void Matrix::MinusRows(int row1, int row2) {
	auto lambda = [this, row1, row2](int beg, int endj) {
		for (int j = beg; j < endj; ++j) {
				arr[row1][j] -= arr[row2][j];
			
		}
	};

	//std::thread a(lambda, 0, _columns/2);
	lambda(0, _columns);
	//a.join();

}

void Matrix::swapLines(int line1, int line2) {
	float* temp = arr[line1];
	arr[line1] = arr[line2];
	arr[line2] = temp;
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




//#include "Matrix.h"
//#include <cmath>
//
//int Matrix::count = 0;
//
//float prec1 = 1000000;
//
//Matrix::Matrix(int rows, int columns) : _rows(rows), _columns(columns) {
//	id = count;
//	++count;
//	arr = new float* [_rows];
//	for (int i = 0; i < _rows; ++i) {
//		arr[i] = new float[_columns];
//		for (int j = 0; j < _columns; ++j)
//			arr[i][j] = 0;
//	}
//}
//
//Matrix::Matrix(const Matrix& other) :Matrix(other._rows, other._columns) {
//	//std::cout << "def copy constructor from " << other.id << " to " << id << "\n";
//	for (int i = 0; i < other._rows; ++i) {
//		for (int j = 0; j < other._columns; ++j) {
//			arr[i][j] = other.arr[i][j];
//		}
//	}
//}
//
//Matrix::Matrix(Matrix&& other) {
//	id = count;
//	//std::cout << "rv copy constructor from " << other.id << " to " << id << "\n";
//	++count;
//	arr = other.arr;
//	_columns = other._columns;
//	_rows = other._rows;
//	other.arr = nullptr;
//}
//
//Matrix::Matrix() :_rows(0), _columns(0) {
//	id = count;
//	++count;
//	arr = nullptr;
//}
//
//Matrix& Matrix::operator=(const Matrix& other) {
//	//std::cout << "def copy operator from " << other.id << " to " << id << "\n";
//	for (int i = 0; i < _rows; ++i) {
//		delete[] arr[i];
//	}
//	delete[] arr;
//
//	_rows = other._rows;
//	_columns = other._columns;
//
//	arr = new float* [_rows];
//	for (int i = 0; i < _rows; ++i) {
//		arr[i] = new float[_columns];
//		for (int j = 0; j < _columns; ++j)
//			arr[i][j] = other.arr[i][j];
//	}
//
//	return *this;
//}
//
//Matrix::~Matrix() {
//	//std::cout << "deleting matrix " << id << "\n";
//	if (arr == nullptr) return;
//	for (int i = 0; i < _rows; ++i) {
//		delete[] arr[i];
//	}
//	delete[] arr;
//}
//
//Matrix& Matrix::operator+=(const Matrix& other) {
//	for (int i = 0; i < _rows; ++i) {
//		for (int j = 0; j < _columns; ++j) {
//			arr[i][j] += other.arr[i][j];
//		}
//	}
//
//	return *this;
//
//}
//
//Matrix Matrix::operator+(const Matrix& other) {
//	Matrix ret(*this);
//
//	return ret += other;
//}
////
////Matrix& Matrix::operator=*(const Matrix& other) {
////	Matrix matrixNew = Matrix(_rows, other._columns);
////	for (int i = 0; i < matrixNew._rows; ++i)
////		for (int j = 0; j < matrixNew._columns; ++j)
////			for (int r = 0; r < _columns; ++r)
////				matrixNew.arr[i][j] += arr[i][r] * other.arr[r][j];
////	return matrixNew;
////}
//
//Matrix& Matrix::operator*=(float l) {
//	for (int i = 0; i < _rows; ++i) {
//		for (int j = 0; j < _columns; ++j) {
//			arr[i][j] *= l;
//		}
//	}
//
//	return *this;
//}
//
//Matrix Matrix::operator*(float l) {
//	Matrix ret(*this);
//	return ret *= l;
//}
//
//Matrix& Matrix::operator/=(float l) {
//	for (int i = 0; i < _rows; ++i) {
//		for (int j = 0; j < _columns; ++j) {
//			arr[i][j] /= l;
//		}
//	}
//
//	return *this;
//}
//
//Matrix Matrix::operator/(float l) {
//	Matrix ret(*this);
//	return ret /= l;
//}
//
//Matrix& Matrix::operator=(Matrix&& other) {
//	//std::cout << "rv copy operator from " << other.id << " to " << id << "\n";
//	int i = 0;
//	int j = 0;
//	delete[] arr;
//	arr = other.arr;
//	arr[i][i] = arr[j][j];
//	_columns = other._columns;
//	_rows = other._rows;
//	other.arr = nullptr;
//
//	return *this;
//}
//
//
//void Matrix::MultiplyRow(int row, float l) {
//	for (int i = 0; i < _columns; ++i) arr[row][i] *= l;
//}
//
//void Matrix::PlusRows(int row1, int row2) {
//	for (int i = 0; i < _columns; ++i) arr[row1][i] += arr[row2][i];
//}
//
//void Matrix::MinusRows(int row1, int row2) {
//	for (int i = 0; i < _columns; ++i) arr[row1][i] -= arr[row2][i];
//}
//
//void Matrix::swapLines(int line1, int line2) {
//	float* temp = arr[line1];
//	arr[line1] = arr[line2];
//	arr[line2] = temp;
//}
//
//void Matrix::ToUpTriangle() {
//	int min = _rows < _columns ? _rows : _columns;
//
//	for (int i = 0; i < min; ++i) {
//		if (arr[i, i] == 0) break;
//
//		int maxRow = i;
//		for (int j = i + 1; j < _rows; ++j)
//			if (arr[j, i] > arr[maxRow, i] && arr[j, i] != 0) maxRow = j;
//		swapLines(i, maxRow);
//
//
//		MultiplyRow(i, 1 / arr[i][i]);
//		for (int j = i + 1; j < _rows; ++j) {
//			float c = arr[j][i];
//			if (c == 0) continue;
//
//			MultiplyRow(i, c);
//			MinusRows(j, i);
//			MultiplyRow(i, 1 / c);
//
//		}
//	}
//}
//
//Matrix::operator std::string() const {
//	std::string ans = "";
//
//	for (int i = 0; i < _rows; i++) {
//		for (int j = 0; j < _columns; ++j)
//			ans += std::to_string((floorf(arr[i][j] * prec1) / prec1)) + " ";
//		ans += "\n";
//	}
//
//	return ans;
//}
