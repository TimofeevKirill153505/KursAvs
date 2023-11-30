#include <iostream>
#include "FuncRow.h"
#include "Matrix.h"
#include <functional>

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

float prec2 = 10000000;

Matrix* GetY(CoeffMatrixCounter f, Piece piece, int numbOfPieces) {
	float h = (piece.b - piece.a) / numbOfPieces;

	float x = piece.a;
	Matrix* Y = new Matrix[numbOfPieces + 1];
	for (int i = 0; i < numbOfPieces + 1; ++i) {
		Y[i] = f(x);
		x += h;
		//std::cout << std::string(Y[i]) << "\n\n\n";
	}

	return Y;
}

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
	float h = (piece.b - piece.a) / numbOfPieces;
	//Matrix* Y = GetY(f, piece, numbOfPieces);
	float x = piece.a;
	//Matrix* Y = new Matrix[numbOfPieces + 1];
	Matrix s = f(x) + f(piece.b);
	x += h;
	//std::cout << std::string(s) << "\n\n";
	for (int i = 1; i < numbOfPieces; ++i) {
		if (i % 2 == 0) s += f(x) * 2;
		else s += f(x) * 4;
		x += h;
		
	}

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

Matrix Mult(Matrix& m1, Matrix& m2) {
	return m1.Multiply(m2);
}

Matrix DiffSquare(Matrix& m, int variable) {
	return m.DiffSquare(variable);
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
		float* incArr = new float[numbOfMembers];
		for (int i = 0; i < numbOfMembers; ++i) {
			incArr[i] = frow[i].Diff().Diff().Count(x);
			//A.Increase(i,i, frow[i].Diff().Diff().Count(x));
			//std::cout << i << "th number " << A.get(i,i) <<  " delta " << frow[i].Diff().Diff().Count(x) <<" ";
			incArr[i] += frow[i].Diff().Count(x) * p(x);
			//std::cout << A.get(i, i) << " delta " << frow[i].Diff().Count(x) * p(x) << " ";
			incArr[i] += frow[i].Count(x) * q(x);
			//std::cout << A.get(i, i) <<  " delta " << frow[i].Count(x) * q(x) << "\n";

		}

		incArr[0] -= f(x);
		A.WriteToDiag(incArr);
		delete[] incArr;
		auto M = Mult(A, A);
		//std::cout << "A" << counter <<" = " << "\n";
		//std::cout << std::string(M) << "\n\n\n";
		++counter;
		return M;
		};

	Matrix intgr = IntSimpson(lambda, numbOfPieces, piece);
	//std::cout << std::string(intgr) << "\n\n\n";

	Matrix matr(numbOfMembers - 1, numbOfMembers);

	for (int i = 1; i < numbOfMembers; ++i) {
		Matrix df = DiffSquare(intgr, i);

		matr.CopyDiffToMatrix(df, i);
	}

	//std::cout << "До треуголирования\n" << std::string(matr) << "\n\n";
	matr.ToUpTriangle();
	//std::cout << "После треуголирования\n" << std::string(matr) << "\n\n";
	float* coeffs = matr.backMove();

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
		//std::cout << myround(x, prec2) <<
		//	" Полученное решение : " << myround(frow.Count(x), prec2) <<
		//	"   Ответ: " << myround(ans(x), prec2) << "  Невязка: " <<
		//	myround(delt[i], prec2) << "\n";
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
	Matrix A(5, 5);
	A.Increase(1, 1, -2);
	std::cout << std::string(A) << "\n\n";
	A.Increase(2, 2, 2);
	int i = 1;
	Function p_t = [](float x)->float { return 0; };
	Function q_t = [](float x) { return 1; };
	Function f_t = [](float x)->float { return x * x + 3 * x - 7; };
	Function lambda = [](float x)->float { return x * x + 3 * x - 9; };

	Piece piece_t = { 0, 1 };
	Cond cond_t = { -9, -5 };
	const int numbOfMembers = 1000;
	const int numbOfPoints = 50;
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