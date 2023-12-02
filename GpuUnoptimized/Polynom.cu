#include "Polynom.h"

float myround(float f, float prec) {
	return floorf(f * prec) / prec;
}

float prec = 100;
const int SIZE = 3;

int Polynom::getPow() const {
	return _base + 2;
}

Polynom::Polynom(int pow) :_base(pow - 2) {
	for (int i = 0; i < SIZE; ++i) _pol[i] = 0;
}

Polynom::Polynom(const Polynom& p) :Polynom(p.getPow()) {
	for (int i = 0; i < SIZE; ++i) {
		_pol[i] = p._pol[i];
	}
	//_base = p._base;

}

Polynom::Polynom(Polynom&& p) {
	for (int i = 0; i < SIZE; ++i) {
		_pol[i] = p._pol[i];
	}
	_base = p._base;
}

Polynom::Polynom(float* k) :Polynom(2) {

	for (int i = 0; i < SIZE; ++i) _pol[i] = k[i];
}

Polynom::Polynom() {
	_base = 0;
}

Polynom::~Polynom() {
	//delete[] _pol;
}

float Polynom::Count(float x) {
	//if ( == 0) return 0;
	if (x == 0) {
		if (_base <= 0) return _pol[0 - _base];
		else return 0;
	}
	float sum = 0;
	float h = powf(x, _base + 2);
	for (int i = SIZE - 1; i >= 0 && i + _base >= 0; --i, h /= x) {
		if (h != INFINITY && h != NAN)
			sum += h * _pol[i];
	}


	return sum;
}

Polynom Polynom::Diff() {
	if (_base <= -2) return 0;
	Polynom df(getPow() - 1);
	for (int i = 0; i < SIZE; ++i) {
		df._pol[i] = _pol[i] * (i + _base);
	}

	return df;
}

Polynom::operator std::string() const {
	std::string str = " ";
	for (int i = SIZE - 1; i > 0; --i) {
		if (myround(_pol[i], prec) == 0) continue;
		if (myround(_pol[i], prec) > 0 && i != SIZE - 1) str += "+";
		if (abs(myround(_pol[i], prec)) != 1) str += std::to_string(abs(myround(_pol[i], prec)));
		else {
			if (myround(_pol[i], prec) < 0) str += '-';
		}
		str += "x";
		if (i + _base != 1) str += std::to_string(i + _base);
	}
	if (_base >= 0) {
		if (myround(_pol[0], prec) != 0) {
			if (myround(_pol[0], prec) > 0) str += "+";
			str += std::to_string(myround(_pol[0], prec));
		}
	}
	return str;
}

float& Polynom::operator[](unsigned int i) {
	return _pol[i - _base];
}

Polynom& Polynom::operator+=(Polynom& other) {
	//int size = std::max(getPow(), other.getPow());
	//float* arr = new float(size + 1);
	float arr[SIZE];

	for (int i = 0; i < SIZE; ++i) _pol[i] += other[i];

	return *this;
}

Polynom Polynom::operator+(Polynom& other) {
	Polynom ret(*this);

	return ret += other;
}

Polynom& Polynom::operator-=(Polynom& other) {
	/*int size = std::max(getPow(), other.getPow());
	float* arr = new float(size + 1);
	for (int i = 0; i < SIZE; ++i) arr[i] = _pol[i];
	delete[] _pol;*/
	/*_length = size + 1;
	_pol = arr;*/

	for (int i = 0; i < SIZE; ++i) _pol[i] -= other[i];

	return *this;
}

Polynom Polynom::operator-(Polynom& other) {
	Polynom ret(*this);

	return ret += other;
}

Polynom& Polynom::operator*=(float l) {
	for (int i = 0; i < SIZE; ++i) _pol[i] *= l;

	return *this;
}

Polynom Polynom::operator*(float l) {
	Polynom ret(*this);

	return ret *= l;
}

Polynom& Polynom::operator/=(float l) {
	for (int i = 0; i < SIZE; ++i) _pol[i] /= l;

	return *this;
}

Polynom Polynom::operator/(float l) {
	Polynom ret(*this);

	return ret /= l;
}

//Polynom& Polynom::operator*=(Polynom& other) {
//	int newPow = getPow() + other.getPow();
//	int newBase = newPow - 2;
//
//
//	//for (int i = 0; i < size + 1; ++i) arr[i] = 0;
//	float arr[3];
//	for (int i = 0; i < SIZE; ++i) {
//		for (int k = 0; k < SIZE; ++k) {
//			arr[((i + _base) + (k + other._base)) - newBase] += _pol[i] * other._pol[k];
//		}
//	}
//
//	for (int i = 0; i < SIZE; ++i) {
//		_pol[i] = arr[i];
//	}
//	return *this;
//}

//Polynom Polynom::operator*(Polynom& other) {
//	Polynom ret(*this);
//
//	return ret *= other;
//}

Polynom& Polynom::IncreasePow(int additionalPow) {
	// TODO: вставьте здесь оператор return
	_base += additionalPow;

	return *this;
}

Polynom& Polynom::operator=(Polynom& other) {

	for (int i = 0; i < SIZE; ++i) _pol[i] = other._pol[i];
	_base = other._base;
	return *this;
}

Polynom& Polynom::operator=(Polynom&& other) {
	for (int i = 0; i < SIZE; ++i) _pol[i] = other._pol[i];
	_base = other._base;
	return *this;
}
