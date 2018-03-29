#include <iostream>
#include <fstream>
#include <ctime>

extern "C" int decode(char * input, char * output, int size);
extern "C" int encode(char * input, char * output, int size);

int roundUp(int numToRound, int multiple)
{
    if (multiple == 0)
        return numToRound;

    int remainder = abs(numToRound) % multiple;
    if (remainder == 0)
        return numToRound;

    if (numToRound < 0)
        return -(abs(numToRound) - remainder);
    else
        return numToRound + multiple - remainder;
}

int main () {
	//system("pause");
    std::clock_t    start = std::clock();
    char * inputbuf = new char [3200000];
    char * outputbuf = new char [3200000];

    int outputsize;
    std::ifstream file("test.mkv", std::ios::binary);
    std::ofstream outfile("test.encode.new", std::ios::binary);
    while (file.good()) {
        file.read(inputbuf, 320000); // Read from file
//        std::clock_t    start = std::clock();       
        outputsize = encode(outputbuf, inputbuf, file.gcount());
//        std::cout << "Time: " << (std::clock() - start) / (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;
        outfile.write(outputbuf, outputsize);
    }
    file.close();
    outfile.close();
    delete[] inputbuf;
    delete[] outputbuf;
    /*std::cout << "Time: " << (std::clock() - start) / (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;

    std::clock_t    start2 = std::clock();
    char * inputbuf2 = new char [300000000];
    char * outputbuf2 = new char [300000000];
    std::ifstream file2("test.encode.new", std::ios::binary);
    std::ofstream outfile2("test.decode.new", std::ios::binary);
    while (file2.good()) {
        file2.read(inputbuf2, 100000); // Read from file
//        std::clock_t    start2 = std::clock();
        outputsize = decode(inputbuf2, outputbuf2, file2.gcount());
//        std::cout << "Time: " << (std::clock() - start2) / (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;
        outfile2.write(outputbuf2, outputsize);
    }
    file2.close();
    outfile2.close();
    delete[] inputbuf2;
    delete[] outputbuf2;
    std::cout << "Time: " << (std::clock() - start2) / (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;
	*/
    return 0;
}