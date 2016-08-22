#include <iostream>
#include <fstream>
#include <ctime>
#include <chrono>

extern "C" int decode(void * input, void * output, int size);
extern "C" int encode(void * input, void * output, int size);
extern "C" int debug_getlc();
extern "C" void debug_setlc(int);

int main () {
    char * inputbuf = new char [200000];
    char * outputbuf = new char [250000];

    int outputsize;
    std::ifstream file("test.mkv", std::ios::binary);
    std::ofstream outfile("test.encode", std::ios::binary);

    std::chrono::nanoseconds cum(0);
    auto begin = std::chrono::high_resolution_clock::now();
    while (file.good()) {
        file.read(inputbuf, 100000); // Read from file
        begin = std::chrono::high_resolution_clock::now();
        outputsize = encode(inputbuf, outputbuf, file.gcount()); // encode several times and get the average time
        cum += std::chrono::high_resolution_clock::now() - begin;
        outfile.write(outputbuf, outputsize);
    }
    std::cout << "Time: " << std::chrono::duration_cast<std::chrono::milliseconds> (cum).count() << std::endl;/// (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;
    file.close();
    outfile.close();

    std::ifstream file2("test.encode", std::ios::binary);
    std::ofstream outfile2("test.decode", std::ios::binary);
    cum = std::chrono::high_resolution_clock::duration::zero();
    while (file2.good()) {
        file2.read(inputbuf, 100000); // Read from file
        begin = std::chrono::high_resolution_clock::now();
        outputsize = decode(inputbuf, outputbuf, file2.gcount());
        cum += std::chrono::high_resolution_clock::now() - begin;
        outfile2.write(outputbuf, outputsize);
    }
    std::cout << "Time: " << std::chrono::duration_cast<std::chrono::milliseconds> (cum).count() << std::endl;/// (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;
    file2.close();
    outfile2.close();
    delete[] inputbuf;
    delete[] outputbuf;
    
    //std::system("pause");
    return 0;
}
