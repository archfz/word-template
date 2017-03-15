#include "WordProcessingMerger.h"
#include "WordProcessingCompiler.h"

#include <exception>
#include <iostream>
#include <ctime>
#include <string>
#include <algorithm>
#include <stdio.h>

#include "dep/json.hpp"

#include "src/args.hpp"

using namespace DocxFactory;
using namespace std;
using json = nlohmann::json;

/**
 * Exit with error and write message.
 * 
 * @param message Message to print.
 */
void error(string message) {
	cout << "ERROR: " << message << "\n";
	exit(1);
}

/**
 * Exit with exception error.
 * 
 * @param e Exception.
 */
void error(const exception &e) {
	error(e.what());
}

/**
 * Apply provided job definitions to the document.
 *  
 * @param jobs JSON array of jobs.
 * @param merger Word document.
 */
void applyJobs(json jobs, WordProcessingMerger &merger) {
	if (!jobs.is_array()) {
		error("Jobs argument JSON must be an array of objects describing jobs.");
	}

	int atJob = 0;
	for (auto it = jobs.begin(); it != jobs.end(); it++) {
		cout << "+ STARTING job #" << ++atJob << "\n";
		json job = it.value();

		if (!job.is_object()) {
			throw invalid_argument("All jobs must be objects.");
		}

		if (job.find("paste") == job.end()) {
			throw invalid_argument("'paste' bookmark is required.");
		}

		if (job["paste"].type() != json::value_t::string) {
			throw invalid_argument("'paste' must be a string that points to a bookmark.");
		}

		string paste = job["paste"];

		// Replaces all placeholder values.
		if (job.find("values") != job.end()) {
			if (job["values"].type() != json::value_t::object) {
				throw invalid_argument("'values' must be an object keyed by placeholder names with values replacements.");
			}

			for (auto iit = job["values"].begin(); iit != job["values"].end(); iit++) {
				cout << "- PLACING for " <<  iit.key() << " : " << iit.value() << "\n";

				// Convert all values to string.
				ostringstream os;
				os << iit.value();
				merger.setClipboardValue(paste, iit.key(), os.str());
			}
		}
		

		cout << "- PASTING " << paste << "\n";
		merger.paste(paste);

		cout << "\n";
	}
}

/**
 * Main.
 * 
 * Options:
 * 	-d <directory>  	: Path to destination directory. Default current.
 *  -f <output-name>    : Output file name. Default <original-name>_compiled.
 * 	
 * Usage: [options] <template-path> <jobs-json>
 */
int main(int argc, char* argv[]) {
	if (argc < 2) {
		error("You must provide the template and the generation jobs.");
	}

	CmdArgs args = CmdArgs(argc, argv);

	string templatePath = argv[argc - 2];

	// Make sure the template file path doesn't end with slash. 
	int i = templatePath.length() - 1;
	while (templatePath[templatePath.length() - 1] == '/') templatePath.pop_back();

	// Get the filename from the template path.
	size_t lastSlashIndex = templatePath.rfind("/");
	string templateName = templatePath.substr(lastSlashIndex == string::npos ? 0 : lastSlashIndex + 1);

	// Get the extension of the template document and remove it from the
	// template name. Also validate the extension as it is critical.
	size_t lastDotIndex = templateName.rfind(".");
	if (lastDotIndex == string::npos) {
		error("Could not determine template document extension from filename: " + templateName);
	}
	string templateExt = templateName.substr(lastDotIndex + 1);
	if (templateExt != "docx") {
		error("Only .docx document formats are supported. Provided: " + templateExt);
	}
	templateName = templateName.substr(0, lastDotIndex);

	// Get the compilation destination directory.
	string destinationDir = "";
	if (args.has("-d")) {
		destinationDir = args.get("-d");
	}
	// Ensure slash at the end of the destination to append filename.
	if (destinationDir.length() > 1 && destinationDir[destinationDir.length() - 1] != '/') {
		destinationDir += "/";
	}

    // Determine the output document name.
	string outputName = templateName + "_compiled";
	if (args.has("-f")) {
	    outputName = args.get("-f");
	}

	// Parse the jobs argument as JSON.
	json jobs;
	try {
		jobs = json::parse(argv[argc-1]);
	} catch (const exception &e) {
		error(e);
	}

	// Compile template to dfw format for the parser.
	string dfwPath = destinationDir + templateName + ".dfw";
	try {
		WordProcessingCompiler& l_compiler = WordProcessingCompiler::getInstance();
		l_compiler.compile(templatePath, dfwPath);
	}
	catch (const exception& e) {
	    cout << "While generating dfw.\n";
		error(e);
	}

	// Using the jobs JSON definition replace and duplicate content
	// from the provided template document.
	try {
		WordProcessingMerger& l_merger = WordProcessingMerger::getInstance();
		l_merger.load(dfwPath);

		cout << "Begin executing compilation jobs...\n";
		applyJobs(jobs, l_merger);

		string savePath = destinationDir + templateName + "." + templateExt;
		l_merger.save(savePath);
		cout << "Compiled document saved to " << savePath << "\n";
	} catch (const exception& e) {
	    cout << "While compiling word.\n";
		error(e);
	}

	// Cleanup.
	remove(dfwPath.c_str());
	return 0;
}
