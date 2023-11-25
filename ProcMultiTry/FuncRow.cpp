#include "FuncRow.h"

FuncRow::FuncRow(int numb, Generator f) {
	this->numb = numb;
	_polynoms = new Polynom[numb];

	for (int i = 0; i < numb; ++i) {
		_polynoms[i] = f(i);
	}
}

FuncRow::FuncRow() {
	_polynoms = nullptr;
	numb = 0;
}

FuncRow::FuncRow(FuncRow&& frow) {
	_polynoms = frow._polynoms;
	frow._polynoms = nullptr;
	numb = frow.numb;
}

FuncRow::FuncRow(const FuncRow& frow) {
	_polynoms = new Polynom[frow.numb];
	for (int i = 0; i < frow.numb; ++i) {
		_polynoms[i] = frow._polynoms[i];
	}

	numb = frow.numb;
}

FuncRow& FuncRow::operator=(FuncRow&& frow) {
	delete[] _polynoms;
	_polynoms = frow._polynoms;
	numb = frow.numb;
	frow._polynoms = nullptr;

	return *this;
}

FuncRow& FuncRow::operator=(FuncRow& frow) {
	delete[] _polynoms;
	_polynoms = new Polynom[frow.numb];
	numb = frow.numb;
	for (int i = 0; i < numb; ++i) _polynoms[i] = frow._polynoms[i];

	return *this;
}

FuncRow::~FuncRow() {
	delete[] _polynoms;
}

float FuncRow::Count(float x) {
	float sum = 0;
	for (int i = 0; i < numb; ++i) {
		sum += _polynoms[i].Count(x);
	}

	return sum;
}

FuncRow::operator Polynom() const {
	Polynom P(0);
	for (int i = 0; i < numb; ++i) {
		P += _polynoms[i];
	}

	return P;
}

Polynom& FuncRow::operator[](int i) const {
	return _polynoms[i];
}

FuncRow:: operator std::string() const {
	std::string str = "";
	for (int i = 0; i < numb; ++i) str += (std::string)_polynoms[i] + " + ";
	str += "0";
	return str;
}