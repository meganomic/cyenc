# cyenc
How to use?! It exports two functions. These.

- uint64_t encode(unsigned char* input_buffer, unsigned char* output_buffer, uint64_t size_of_input)
- uint64_t decode(unsigned char* input_buffer, unsigned char* output_buffer, uint64_t size_of_input)

The function returns size_of_output.
The output_buffer MUST be sufficently large to take all the data. Undefined things will happen if it's not. Just make it twice as big as input or something. Whatever. #yolo

Decode is currently broken
