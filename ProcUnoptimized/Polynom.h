#pragma once
#include <string>
#include <cmath>
#include <algorithm>

float myround(float f, float prec);
class Polynom {
private:
	//int _length;
	float _pol[3] = { 0,0,0 };
	int _base;
public:
	int getPow () const;

	Polynom(int pow);
	Polynom(const Polynom& p);
	Polynom(Polynom&& p);
	Polynom(float* k);
	Polynom();

	~Polynom();

	float Count(float x);
	Polynom Diff();

	operator std::string() const;

	float& operator[](unsigned int i);
	Polynom& operator+=(Polynom& other);
	Polynom operator+(Polynom& other);
	Polynom& operator-=(Polynom& other);
	Polynom operator-(Polynom& other);
	Polynom& operator*=(float l);
	Polynom operator*(float l);
	Polynom& operator/=(float l);
	Polynom operator/(float l);
	//Polynom& operator*=(Polynom& other);
	//Polynom operator*(Polynom& other);

	Polynom& IncreasePow(int additionalPow);

	Polynom& operator=(Polynom& other);
	Polynom& operator=(Polynom&& other);
	
};

