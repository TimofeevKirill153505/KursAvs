#pragma once
#include <string>
#include <iostream>

class Matrix
{
private:
	int _columns;
	int _rows;
	static int count;
	int id;
public:
	float** arr = nullptr;
	int getColumns() {
		return _columns;
	}

	int getRows() {
		return _rows;
	}

	Matrix(int rows, int columns);
	Matrix(const Matrix& other);
	Matrix(Matrix&& other);
	Matrix();
	Matrix& operator=(const Matrix& other);
	~Matrix();

	Matrix& operator+= (const Matrix& other);
	Matrix operator+ (const Matrix& other);
	/*Matrix& operator*=(const Matrix& other);
	Matrix& operator* (const Matrix& other);*/
	Matrix& operator*= (float l);
	Matrix operator* (float l);
	Matrix& operator /= (float l);
	Matrix operator/ (float l);
	Matrix& operator=(Matrix&& other);

	void MultiplyRow(int row, float l);
	void PlusRows(int row1, int row2);
	void MinusRows(int row1, int row2);
	void swapLines(int line1, int line2);
	void ToUpTriangle();

	operator std::string() const;

};

