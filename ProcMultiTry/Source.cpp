#include <iostream>
#include "FuncRow.h"
#include "Matrix.h"
#include <functional>

const float PI = 3.1415926f;

typedef  std::function<Matrix(float x)> CoeffMatrixCounter;
typedef std::function<float(float)> Function;

//����� ��� �����������������: ���� ���������� ������ f(x)
//�������� �������� ������������ ������
// � ������ �������� ������� �� ����
// � ��������� ����������� �� ����� �����������


//TODO �������������� ����������� ����������� � �������� �����������
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
	Matrix* Y = GetY(f, piece,
		numbOfPieces); //������ ���������� ������� �������� ������� (���������� �� ��� ���������� � �� ����)
	float h = (piece.b - piece.a) / numbOfPieces;
	Matrix s = Y[0] + Y[numbOfPieces];
	for (int i = 1; i < numbOfPieces; ++i)
		if (i % 2 == 0) s += Y[i] * 2;
		else s += Y[i] * 4;

	delete[] Y;
	return s * h / 3;
}

Matrix Mult(Matrix& m1, Matrix& m2) {
	Matrix M(m1.getRows(), m1.getColumns());
	for (int i = 0; i < m1.getColumns(); ++i)
		for (int j = 0; j < m1.getColumns(); ++j)
			M.arr[i][j] = m1.arr[i][i] * m2.arr[j][j];

	return M;
}

Matrix DiffSquare(Matrix& m, int variable) {
	Matrix M(m);

	for (int i = 0; i < m.getRows(); ++i) {
		if (i == variable) continue;
		for (int j = 0; j < m.getColumns(); ++j) {
			if (j == variable) continue;
			M.arr[i][j] = 0;
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

	for (int i = 1; i < numbOfMembers; ++i) {
		Matrix df = DiffSquare(intgr, i);

		for (int j = 1; j < numbOfMembers; ++j) matr.arr[i - 1][j - 1] = df.arr[i][j] + df.arr[j][i];

		matr.arr[i - 1][numbOfMembers - 1] = -(df.arr[i][0] + df.arr[0][i]);
	}

	//std::cout << "�� ���������������" << std::string(matr) << "\n\n";
	matr.ToUpTriangle();
	//std::cout << "����� ���������������" << std::string(matr) << "\n\n";
	float* coeffs = backMove(matr);

	for (int i = 1; i < numbOfMembers; ++i) frow[i] *= coeffs[i - 1];

	delete[] coeffs;

	return frow;
}

void ShowDataTest(FuncRow frow, Function ans, Piece piece, int numbOfPoints) {
	//std::cout << ("���������� ���:\n");
	//std::cout << (std::string)frow;

	float h = (piece.b - piece.a) / numbOfPoints;
	float x = piece.a;
	float* delt = new float[numbOfPoints + 1];
	for (int i = 0; i <= numbOfPoints; ++i, x += h) {
		delt[i] = abs(frow.Count(x) - ans(x));
		/*std::cout << myround(x, prec2) <<
			" ���������� ������� : " << myround(frow.Count(x), prec2) <<
			"   �����: " << myround(ans(x), prec2) << "  �������: " <<
			myround(delt[i], prec2) << "\n";*/
	}

	float Norm = 0;
	for (int i = 0; i < numbOfPoints + 1; ++i) if (Norm < delt[i]) Norm = delt[i];
	delete[] delt;
	std::cout << "����� �������: " << Norm << "\n";
}

void dotest(Function p_t, Function q_t, Function f_t, Function lambda, Piece piece,
	Cond cond, int i, int numbOfMembers, int numbOfPoints) {
	std::cout << "������������ ��� �������� ������ " << i << "\n";
	auto beg = clock();
	FuncRow frow = MnkInt(p_t, q_t, f_t, numbOfMembers, Anis(cond, piece), 30, piece);
	auto end = clock();
	std::cout << "����� ���������� " << end - beg << " �����������" << "\n";
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
	const int numbOfMembers = 500;
	const int numbOfPoints = 500;
	//Function lambda = (x) => { return 0; };

	/*for (int i = 1; i <= 4; ++i) {
		Polynom pol (i + 2);
		pol[i + 2] = -1;
		pol[i] = 1;
		std::cout << std::string(Anis(cond_t, piece_t)(i)) << " � " << std::string(pol) << std::endl;
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