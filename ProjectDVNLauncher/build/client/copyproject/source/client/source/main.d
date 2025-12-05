module main;

import dvn;

import core.stdc.stdlib : exit;

version (Windows)
{
	import core.runtime;
	import core.sys.windows.windows;
	import std.string;
	
	pragma(lib, "user32");

	extern (Windows)
	int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
				LPSTR lpCmdLine, int nCmdShow)
	{
		int result;

		try
		{
			Runtime.initialize();
			result = myWinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
			Runtime.terminate();
		}
		catch (Throwable e) 
		{
			import std.file : write;

			write("errordump.log", e.toString);

			MessageBoxA(null, e.toString().toStringz(), null,
						MB_ICONEXCLAMATION);
			exit(0);
			result = 0;     // failed
		}

		return result;
	}

	int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
				LPSTR lpCmdLine, int nCmdShow)
	{
		mainEx();
		return 0;
	}
}
else
{
	void main()
	{
		try
		{
			mainEx();
		}
		catch (Throwable e)
		{
			import std.stdio : writeln, readln;
			import std.file : write;

			write("errordump.log", e.toString);
			
			writeln(e);

			exit(0);
		}
	}
}

void mainEx()
{
	runDVN();
}
