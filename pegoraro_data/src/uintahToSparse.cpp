#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <map>
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

void usage_message() {
	cout << endl;
	cout << endl
			<< "Usage: uintahToSparse <width> <height> <depth> <dense_file> <sparse_file>"
			<< endl;
	cout << endl;
}

int main(int argc, char *argv[]) {
	if (argc != 6) {
		usage_message();
		exit(0);
	}

	unsigned width = 0;
	unsigned height = 0;
	unsigned depth = 0;
	try {
		width = std::stoi(argv[1]);
		height = std::stoi(argv[2]);
		depth = std::stoi(argv[3]);
	} catch (const std::exception& e) {
		cerr << "Could not parse width = " << argv[1] << ", height = "
				<< argv[2] << ", depth = " << argv[3] << endl;
		usage_message();
		exit(-1);
	}
	const std::string &in_file(argv[4]);
	const std::string &out_file(argv[5]);

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

	map<double, int> repeated_count;

	// Count number of repetitions for each value
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
				check_in_stream(in_file, in_stream, out_stream);

				if (repeated_count.find(read_val) != repeated_count.end()) {
					repeated_count.at(read_val) += 1;
				} else {
					repeated_count.insert(make_pair(read_val, 1));
				}
			}
		}
	}

	// Get the max
	double val_max = NAN;
	int val_max_count = 0;

	if (repeated_count.size() > 0) {
		auto iter = repeated_count.begin();

		// Initialise to first element
		val_max = iter->first;
		val_max_count = iter->second;

		// Compare with the rest in the container
		iter++;
		for (; iter != repeated_count.end(); ++iter) {
			if (iter->second >= val_max_count) {
				val_max = iter->first;
				val_max_count = iter->second;
			}
		}
	}

	// Reset to start
	in_stream.clear();
	in_stream.seekg(0, ios::beg);

	double background = val_max;
	int num_valid = width * height * depth - val_max_count;

	// Actual read/write loop
	out_stream << width << " " << height << " " << depth << " " << num_valid
			<< " " << background << endl;
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
				check_in_stream(in_file, in_stream, out_stream);

				if (read_val != background) {
					out_stream << x << " " << y << " " << z << " " << read_val
							<< endl;
					check_out_stream(in_stream, out_file, out_stream);
				}
			}
		}
	}

	in_stream.close();
	out_stream.close();
	return 0;
}
