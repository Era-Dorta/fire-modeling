#include <iostream>
#include <fstream>
#include <cstdlib>
using namespace std;

void check_in_stream(const std::string & in_file, std::ifstream& in_stream,
		std::ofstream& out_stream) {
	if (!in_stream) {
		in_stream.close();
		out_stream.close();
		cerr << "Error reading " << in_file << endl;
		exit(-1);
	}
}

void check_out_stream(std::ifstream& in_stream, const std::string &out_file,
		std::ofstream& out_stream) {
	if (!out_stream) {
		in_stream.close();
		out_stream.close();
		cerr << "Error writing to " << out_file << endl;
		exit(-1);
	}
}

int main(int argc, char *argv[]) {
	if (argc != 3) {
		cout << endl;
		cout << endl << "Usage: uintahToSparse <dense_file> <sparse_file>"
				<< endl;
		cout << endl;
		exit(0);
	}
	const std::string &in_file(argv[1]);
	const std::string &out_file(argv[2]);

	std::ifstream in_stream(in_file.c_str(), std::ios_base::in);
	if (!in_stream.is_open()) {
		cerr << "file " << in_file << " could not be open" << endl;
		return -1;
	}

	std::ofstream out_stream(out_file.c_str(), std::ios_base::out);
	if (!out_stream.is_open()) {
		cerr << "file " << out_file << " could not be open" << endl;
		in_stream.close();
		return -1;
	}
	out_stream << std::scientific; // Scientific precision

	unsigned width, height, depth;
	in_stream >> width;
	check_in_stream(in_file, in_stream, out_stream);

	in_stream >> height;
	check_in_stream(in_file, in_stream, out_stream);

	in_stream >> depth;
	check_in_stream(in_file, in_stream, out_stream);

	double background;
	in_stream >> background;
	check_in_stream(in_file, in_stream, out_stream);

	// Cannot easily write at the start of the file and main return
	// is for program status, so read the file twice

	// Count num valid loop
	unsigned num_valid = 0;
	for (unsigned i = 0; i < width; i++) {
		for (unsigned j = 0; j < height; j++) {
			for (unsigned k = 0; k < depth; k++) {
				int x, y, z;
				in_stream >> x;
				check_in_stream(in_file, in_stream, out_stream);

				in_stream >> y;
				check_in_stream(in_file, in_stream, out_stream);

				in_stream >> z;
				check_in_stream(in_file, in_stream, out_stream);

				double read_val;
				in_stream >> read_val;

				if (read_val != background) {
					num_valid++;
				}
			}
		}
	}

	// Reset to start
	in_stream.clear();
	in_stream.seekg(0, ios::beg);

	// Advance to the data
	for (unsigned i = 0; i < 4; i++) {
		double aux;
		in_stream >> aux;
		check_in_stream(in_file, in_stream, out_stream);
	}

	// Actual read/write loop
	out_stream << num_valid << " " << background << endl;
	check_out_stream(in_stream, out_file, out_stream);

	for (unsigned i = 0; i < width; i++) {
		for (unsigned j = 0; j < height; j++) {
			for (unsigned k = 0; k < depth; k++) {
				int x, y, z;
				in_stream >> x;
				check_in_stream(in_file, in_stream, out_stream);

				in_stream >> y;
				check_in_stream(in_file, in_stream, out_stream);

				in_stream >> z;
				check_in_stream(in_file, in_stream, out_stream);

				double read_val;
				in_stream >> read_val;

				if (read_val != background) {
					out_stream << x << " " << y << " " << z << " ";
					out_stream << read_val << endl;
					check_out_stream(in_stream, out_file, out_stream);
				}
			}
		}
	}

	in_stream.close();
	out_stream.close();
	return 0;
}
