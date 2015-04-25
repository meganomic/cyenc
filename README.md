# cyenc
How to use?! It exports two functions. These.

- int encode(char* input_buffer, char* output_buffer, int size_of_input)
- int decode(char* input_buffer, char* output_buffer, int size_of_input)

The function returns size_of_output.
The output_buffer MUST be sufficently large to take all the data. Undefined things will happen if it's not. Just make it twice as big as input or something. Whatever. #yolo

When decoding, make sure to only decode 1 file at a time and in order! It keeps track of various variables internaly. If you do NOT follow this sage advice you will get broken output.

Requires SSE2 and x64 OS
