
#include <iostream>
#include <algorithm>

using namespace std;

class CmdArgs {
	char** begin;
	char** end;

public:

	CmdArgs(int _argc, char* _argv[]) {
		begin = _argv;
		end = _argv + _argc;
	}


	char* get(const std::string & option)
	{
	    char ** itr = std::find(begin, end, option);
	    if (itr != end && ++itr != end)
	    {
	        return *itr;
	    }
	    return 0;
	}

	bool has(const std::string& option)
	{
	    return std::find(begin, end, option) != end;
	}

};