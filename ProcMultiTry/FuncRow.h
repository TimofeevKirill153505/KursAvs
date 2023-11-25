#pragma once
#include "Polynom.h"
#include <functional>


typedef  std::function<Polynom(int i)> Generator;
class FuncRow {
private:
	Polynom* _polynoms;
	int numb;
public:
	FuncRow(int numb, Generator f);
	FuncRow();
	FuncRow(FuncRow&& frow);
	FuncRow(const FuncRow& frow);
	~FuncRow();

	FuncRow& operator=(FuncRow&& frow);
	FuncRow& operator=(FuncRow& frow);


	float Count(float x);

	operator std::string() const;

	operator Polynom() const;

	Polynom& operator[](int i) const;
};

