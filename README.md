# cyenc
How to use?! It exports two functions. These.

- int encode(void* input_buffer, void* output_buffer, int size_of_input)
- int decode(void* input_buffer, void* output_buffer, int size_of_input)

The function returns size_of_output.
The output_buffer MUST be sufficently large to take all the data. Undefined things will happen if it's not. Just make it twice as big as input or something. Whatever. #yolo
