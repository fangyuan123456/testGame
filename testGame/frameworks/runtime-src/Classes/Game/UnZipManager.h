#pragma once
#include "cocos2d.h"
USING_NS_CC;
using namespace std;
enum class UnZipState {
	UN_COMPRESS = 0,
	COMPRESSING,
	COMPRESS_END,
	COPY_END
};
struct unZipStruct {
	string zipPath = "";
	string unzipPath = "";
	string destPath = "";
	function<void(void)> unzipCompleteFunc = NULL;
	function<void(void)> unzipFailFunc = NULL;
};
class UnZipManager {
private:
	UnZipManager();
	~UnZipManager();
	vector<unZipStruct> unZipList;
	mutex unzipUnitListMutex;
	void updateUnZipList(unZipStruct zipData);
	void removeFormUnZipList(unZipStruct zipData);
	string getFileName(string url);
public:
	static UnZipManager * _instance;
	static UnZipManager * getInstance();
	void unZip(string zipPath, string unZipPath, string destPath, function<void(void)> unZipCompleteFunc, function<void(void)> unZipFailFunc);
	bool unCompress(unZipStruct data);
	void startUnCompress(unZipStruct data);
	UnZipState getUnZipState(string zipPath);
	unZipStruct getUnZipData(string path);
	void runCompressEndFunc(unZipStruct unZipData);
	void runCompressFailFunc(unZipStruct unZipData);
	bool moveToDesPath(string srcPath, string destPath);
	void removeDirectory(string path);
};