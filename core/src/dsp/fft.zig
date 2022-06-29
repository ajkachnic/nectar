const std = @import("std");

const Complex = std.math.Complex;

/// A rather unoptimized Fast Fourier Transform implementation, based
/// off of the Mixed-Radix algorithm
pub fn FFT(comptime T: type) type {
    if (T != f64 and T != f32) {
        @compileError("Invalid type for FFT (Fast Fourier Transform): " ++ T);
    }

    return struct {
        const Self = @This();

        const I = Complex(T).init(0.0, 1.0);

        order: usize,
        size: usize,

        /// Initalized an FFT, with a given size.
        /// 
        /// The number of points the FFT will operate on will be 2 ^ `order`.
        pub fn init(order: usize) Self {
            return Self{ .size = order };
        }

        fn fft_inner(
            input: []Complex(T),
            output: []Complex(T),
            n: usize,
            step: usize,
        ) void {
            if (step >= n) return;

            fft_inner(output, input, n, step * 2);
            fft_inner(output[step..], input[step..], n, step * 2);

            var left = input[0 .. n / 2];
            var right = input[n / 2 ..];

            var i: usize = 0;
            while (i < n) : (i += step * 2) {
                // var t = (I.neg().mul(Complex(T).init(std.math.pi, 0)));
            }
        }

        /// Perform an out-of-place FFT. Both arrays must contain at least
        /// `size` elements.
        pub fn run(self: *Self, input: []Complex(T), output: []Complex(T)) void {
            if (self.size == 1) {
                std.mem.copy(Complex(T), output, input);
            }
            std.debug.assert(input.len >= self.size);
            std.debug.assert(output.len >= self.size);
        }
    };
}
