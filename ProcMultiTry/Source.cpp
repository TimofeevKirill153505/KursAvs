#include <iostream>
#include "FuncRow.h"
#include "Matrix.h"
#include <functional>
//#include <thread>

const float PI = 3.1415926f;

typedef  std::function<Matrix(float x)> CoeffMatrixCounter;
typedef std::function<float(float)> Function;

//места для распараллеливания: гетУ вычисления матриц f(x)
//интеграл симпсона суммирование матриц
// в мульте возможно разбить на зоны
// в дифсквере сомнительно но можно попробовать

struct Piece {
	float a;
	float b;
};

struct Cond {
	float y1;
	float y2;
};

int getYcount = 0;


float prec2 = 10000000;


Generator Anis(Cond cond, Piece piece) {
	return [cond, piece](int i)->Polynom {
		if (i == 0) {

			float k = (cond.y2 - cond.y1) / (piece.b - piece.a);
			//k*(x - piece.a) + cond.y1
			float c = cond.y1 - k * piece.a;
			float arr[] = { c,k,0 };
			//auto pol = Polynom(arr);
			//std::cout << std::string(pol) << "\n";
			return Polynom(arr);
		}

		float arr2[3] = { piece.a * piece.b, -(piece.a + piece.b), 1 };
		Polynom polly(arr2);
		//Polynom pol(i - 1);
		//pol[i - 1] = 1;
		//std::cout << (std::string)(pol * polly) << "\n";
		return polly.IncreasePow(i - 1);
		};
}

Matrix IntSimpson(CoeffMatrixCounter f, int numbOfPieces, Piece piece) {
	/*Matrix* Y = GetY(f, piece, numbOfPieces);*/ //должен возвращать матрицы квадрата невязки (возвращает то что возвращает и не ебет)
	float h = (piece.b - piece.a) / numbOfPieces;
	float x = piece.a + h;
	Matrix s = f(piece.a) + f(piece.b);
	Matrix SumOfEven(s.getRows(), s.getColumns());
	Matrix SumOfUneven(s.getRows(), s.getColumns());

	Matrix* soe = &SumOfEven;
	Matrix* sou = &SumOfUneven;

#pragma omp parallel shared(soe, sou, f, numbOfPieces) private(x) num_threads(2)
	{
		float x = piece.a + h + omp_get_thread_num() * h;
		for (int i = omp_get_thread_num() + 1; i < numbOfPieces; i += 2) {
			if (i % 2 == 0) (*soe) += f(x) * 2;
			else (*sou) += f(x) * 4;
			x += 2*h;
		}
	}

	s += SumOfEven + SumOfUneven;

	return s * (h / 3);
}

//Matrix IntSimpson(CoeffMatrixCounter f, int numbOfPieces, Piece piece) {
//	Matrix* Y = GetY(f, piece,
//		numbOfPieces); //должен возвращать матрицы квадрата невязки (возвращает то что возвращает и не ебет)
//	float h = (piece.b - piece.a) / numbOfPieces;
//	Matrix s = Y[0] + Y[numbOfPieces];
//	for (int i = 1; i < numbOfPieces; ++i)
//		if (i % 2 == 0) s += Y[i] * 2;
//		else s += Y[i] * 4;
//
//	delete[] Y;
//	return s * h / 3;
//}

Matrix Mult(Matrix m1, Matrix m2) {

	Matrix M(m1.getRows(), m1.getColumns());

	Matrix* _M = &M;
	Matrix* _m1 = &m1;
	Matrix* _m2 = &m2;
	int cols = m1.getColumns();
	int rows = m1.getRows();
#pragma omp parallel shared(_M, _m1, _m2, cols, rows)
	{
#pragma omp for
		for (int i = 0; i < cols; ++i)
			for (int j = 0; j < rows; ++j)
				_M->arr[i][j] = _m1->arr[i][i] * _m2->arr[j][j];
	}

	return M;
}

Matrix DiffSquare(Matrix& m, int variable) {
	Matrix M(m);
	int rows = M.getRows();
	int cols = M.getColumns();
	Matrix* _M = &M;
#pragma omp parallel shared(_M, rows, cols, variable)
	{
#pragma omp for
	for (int i = 0; i < rows; ++i) {
		if (i == variable) continue;
		for (int j = 0; j < cols; ++j) {
			if (j == variable) continue;
			_M->arr[i][j] = 0;
		}
	}
	}

	return M;
}

float* backMove(Matrix& slau) {
	float* x = new float[slau.getColumns() - 1];

	for (int i = slau.getRows() - 1; i >= 0; --i) {
		int k = i + 1;
		float d = slau.arr[i][slau.getColumns() - 1];
		for (; k < slau.getRows(); ++k) d -= slau.arr[i][k] * x[k];

		x[i] = d;
	}

	return x;
}




FuncRow MnkInt(Function p, Function q, Function f, int numbOfMembers, Generator memb, int numbOfPieces,
	Piece piece) {
	FuncRow frow(numbOfMembers, memb);
	//std::cout << std::string(frow) << "\n\n\n";

	auto lambda =
		[numbOfMembers, frow, p, q, f](float x)->Matrix {
		static int counter = 0;
		Matrix A(numbOfMembers, numbOfMembers);
		//std::cout << std::string(frow) << "\n\n";
		for (int i = 0; i < numbOfMembers; ++i) {
			A.arr[i][i] += frow[i].Diff().Diff().Count(x);
			//std::cout << i << "th number " << A.arr[i][i] << " ";
			A.arr[i][i] += frow[i].Diff().Count(x) * p(x);
			//std::cout << A.arr[i][i] << " ";
			A.arr[i][i] += frow[i].Count(x) * q(x);
			//std::cout << A.arr[i][i] << "\nHis pol " << std::string(frow[i]) << "\n";

		}


		A.arr[0][0] -= f(x);
		auto M = Mult(A, A);
		//std::cout << "A" << counter <<" = " << "\n";
		//std::cout << std::string(A) << "\n\n\n";
		++counter;
		return M;
		};

	Matrix intgr = IntSimpson(lambda, numbOfPieces, piece);
	//std::cout << std::string(intgr) << "\n\n\n";

	Matrix matr(numbOfMembers - 1, numbOfMembers);

	int nom = numbOfMembers;
	Matrix* _matr = &matr;
	Matrix* _intgr = &intgr;
#pragma omp parallel shared(nom, _matr, _intgr)
	{
#pragma omp for
		for (int i = 1; i < nom; ++i) {
			Matrix df = DiffSquare(*(_intgr), i);

			for (int j = 1; j < nom; ++j) _matr->arr[i - 1][j - 1] = df.arr[i][j] + df.arr[j][i];

			_matr->arr[i - 1][nom - 1] = -(df.arr[i][0] + df.arr[0][i]);
		}
	}

	//std::cout << "До треуголирования\n" << std::string(matr) << "\n\n";
	matr.ToUpTriangle();
	//std::cout << "После треуголирования\n" << std::string(matr) << "\n\n";
	float* coeffs = backMove(matr);

	for (int i = 1; i < numbOfMembers; ++i) frow[i] *= coeffs[i - 1];

	delete[] coeffs;

	return frow;
}




void ShowDataTest(FuncRow frow, Function ans, Piece piece, int numbOfPoints) {
	//std::cout << ("Полученный ряд:\n");
	//std::cout << (std::string)frow;

	float h = (piece.b - piece.a) / numbOfPoints;
	float x = piece.a;
	float* delt = new float[numbOfPoints + 1];
	for (int i = 0; i <= numbOfPoints; ++i, x += h) {
		delt[i] = abs(frow.Count(x) - ans(x));
		/*std::cout << myround(x, prec2) <<
			" Полученное решение : " << myround(frow.Count(x), prec2) <<
			"   Ответ: " << myround(ans(x), prec2) << "  Невязка: " <<
			myround(delt[i], prec2) << "\n";*/
	}

	float Norm = 0;
	for (int i = 0; i < numbOfPoints + 1; ++i) if (Norm < delt[i]) Norm = delt[i];
	delete[] delt;
	std::cout << "Норма невязки: " << Norm << "\n";
}

void dotest(Function p_t, Function q_t, Function f_t, Function lambda, Piece piece,
	Cond cond, int i, int numbOfMembers, int numbOfPoints) {
	std::cout << "Интегральный МНК Тестовый пример " << i << "\n";
	auto beg = clock();
	FuncRow frow = MnkInt(p_t, q_t, f_t, numbOfMembers, Anis(cond, piece), 30, piece);
	auto end = clock();
	std::cout << "Время выполнения " << end - beg << " миллисекунд" << "\n";
	ShowDataTest(frow, lambda, piece, numbOfPoints);
}



int main() {

	setlocale(0, "");
	int i = 1;
	Function p_t = [](float x)->float { return 0; };
	Function q_t = [](float x) { return 1; };
	Function f_t = [](float x)->float { return x * x + 3 * x - 7; };
	Function lambda = [](float x)->float { return x * x + 3 * x - 9; };

	Piece piece_t = { 0, 1 };
	Cond cond_t = { -9, -5 };
	const int numbOfMembers = 1000;
	const int numbOfPoints = 1000;
	//Function lambda = (x) => { return 0; };

	/*for (int i = 1; i <= 4; ++i) {
		Polynom pol (i + 2);
		pol[i + 2] = -1;
		pol[i] = 1;
		std::cout << std::string(Anis(cond_t, piece_t)(i)) << " и " << std::string(pol) << std::endl;
	}*/

	dotest(p_t, q_t, f_t, lambda, piece_t, cond_t, i, numbOfMembers, numbOfPoints);

	Function e3 = [](float x)->float {return expf(3 * x); };
	p_t = [](float x)->float {return  x * x + 6; };
	q_t = [](float x)->float {return  pow(2, -x); };
	f_t = [e3](float x)->float {return  9 * e3(x) + 3 * (x * x + 6) * e3(x) + pow(2, -x) * e3(x); };
	lambda = [](float x)->float {return  expf(3 * x); };
	piece_t = { 0, 1 };
	cond_t = { 1, expf(3) };
	i = 2;

	dotest(p_t, q_t, f_t, lambda, piece_t, cond_t, i, numbOfMembers, numbOfPoints);

	p_t = [](float x)->float {return  0; };
	q_t = [](float x)->float {return 1; };
	f_t = [](float x)->float {return  2 * x - PI; };
	lambda = [](float x)->float {return 2 * x - PI + PI * cos(x); };
	cond_t = { 0, lambda(1) };
	piece_t = { 0, 1 };

	i = 3;
	dotest(p_t, q_t, f_t, lambda, piece_t, cond_t, i, numbOfMembers, numbOfPoints);


	p_t = [](float x)->float {return  2; };
	q_t = [](float x)->float {return  1; };
	f_t = [](float x)->float {return  0; };
	lambda = [](float x)->float {return  expf(-x) + x * expf(-x); };
	piece_t = { 0, 1 };
	cond_t = { lambda(0), lambda(1) };

	i = 4;
	dotest(p_t, q_t, f_t, lambda, piece_t, cond_t, i, numbOfMembers, numbOfPoints);

}

//#include <omp.h>
//
//#include <iostream>

//int main() {
//	int i;
//	int arr[10][10][2];
//	for (int i = 0; i < 10; ++i) {
//		for (int j = 0; j < 10; ++j) {
//			arr[i][j][0] = i * j;
//
//			arr[i][j][0] = i;
//			arr[i][j][1] = 0;
//		}
//	}
//	int arrSize = 10;
//	--arrSize;
//	++arrSize;
//#pragma omp parallel shared(arr)
//{
//#pragma omp for
//	for (int i = 0; i < arrSize; ++i) {
//		for(int j = 0; j < arrSize; ++j)
//		arr[i][j][1] = omp_get_thread_num();
//		}
//	
//}
//	for (int i = 0; i < 10; ++i) {
//		for(int j = 0; j < 10; ++j)
//		std::cout << i << ",  " << j << " by thread" << arr[i][j][1] << "\n";
//	}
//
//	return 0;
//}