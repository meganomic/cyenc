# cyenc - AVX version
I've begun a rewrite of this since the original code is bad. I want the code to be at least at the beginner level so I'm doing that. cyencavx.asm contains a encode function that *works*. There's some weird things going on with it that I don't understand yet. Currently for windows only since that is the platform I'm using. I've put in some effort to make it work on linux but because of said *weird* thing it doesn't.

- int encode(void* output_buffer, void* input_buffer, int size_of_input)

The function returns size_of_output.
As the old version, make sure the output buffer is sufficiently large.
Notice that I've changed the order of the input/output buffer arguments. I did that because of some reason that I have since forgotten but I'm sure it was a very good reason.

As for speed, this is about 4 times as fast as the previous version. I'll get some actual benchmarks when I've figured out what's wrong with it.

# cyenc - SSE version
##### Only kept for historical and shaming reasons
How to use?! It exports two functions. These.

- int encode(void* input_buffer, void* output_buffer, int size_of_input)
- int decode(void* input_buffer, void* output_buffer, int size_of_input)

The function returns size_of_output.
The output_buffer MUST be sufficently large to take all the data. Undefined things will happen if it's not. Just make it twice as big as input or something. Whatever. #yolo

When decoding, make sure to only decode 1 yenc part at a time and in order! It keeps track of various variables internaly. If you do NOT follow this sage advice you will get broken output.

Requires SSE2 and x64 OS

## Performance

Using a ~230mb test file I got these results.

| Program      | Function   | Speed      |
| ----------   | ---------- | ---------- |
| cyenc        | encode     | ~650ms     |
| cyenc        | decode     | ~650ms     |
| python2-yenc | encode     | ~1850ms    |
| python2-yenc | decode     | ~1250ms    |

## Conclusion

#### So should I use cyenc?
No.

#### Why not?
Because the additional speed isn't worth it.
