using System;
using System.Runtime.InteropServices;

namespace CSharpImportAssembly
{
    class Program
    {
        [DllImport("NumGrinder.dll")]
        public static extern int Multiply(int a, int b);

        [DllImport("NumGrinder.dll")]
        public static extern int Divide(int a, int b);

        [DllImport("NumGrinder.dll")]
        public static extern int Factorial(int n);

        static void Main(string[] args)
        {
            Console.WriteLine(Multiply(2, 21));
            Console.WriteLine(Divide(2674, 2));

            Console.WriteLine();

            for (var i = 0; i < 10; ++i)
                Console.WriteLine(Factorial(i));

            Console.ReadKey();
        }
    }
}
