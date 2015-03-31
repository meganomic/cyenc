# cyenc
How to use?! It exports one function. This.

encode(char* input_buffer, char* output_buffer, int size_of_input)

or maybe

encode(void* input_buffer, void* output_buffer, int size_of_input)

I don't know. Whatever, just give it a pointer to a contiguous array.
The output_buffer MUST be sufficently large to take all the data. Undefined things will happen if it's not. Just make it twice as big as input or something. Whatever. #yolo
