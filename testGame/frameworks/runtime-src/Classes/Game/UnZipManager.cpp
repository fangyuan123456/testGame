#include "UnZipManager.h"
#ifdef MINZIP_FROM_SYSTEM
#include<minizip/unzip.h>
#else
#include"unzip.h"
#endif

#define BUFFER_SIZE 8192
#define MAX_FILENAME 512
UnZipManager * UnZipManager::_instance = nullptr;
UnZipManager::UnZipManager()
{

}

UnZipManager::~UnZipManager()
{
}

void UnZipManager::updateUnZipList(unZipStruct zipData)
{
	bool isFind = false;
	for (auto iter = unZipList.begin(); iter != unZipList.end(); iter++) {
		if (iter->zipPath == zipData.zipPath) {
			iter->unzipPath = zipData.unzipPath;
			iter->destPath = zipData.destPath;
			iter->unzipCompleteFunc = zipData.unzipCompleteFunc;
			iter->unzipFailFunc = zipData.unzipFailFunc;
			isFind = true;
		}
	}
	if (!isFind) {
		unZipList.push_back(zipData);
	}
}
void UnZipManager::removeFormUnZipList(unZipStruct zipData)
{
	for (auto iter = unZipList.begin(); iter != unZipList.end(); iter++) {
		if (iter->zipPath == zipData.zipPath) {
			unZipList.erase(iter);
			return;
		}
	}
}
string UnZipManager::getFileName(string url)
{
	auto pos = url.find_last_of("/");
	auto dianPos = url.find_last_not_of(".");
	string fileName = url.substr(pos + 1, dianPos - pos - 1);
	return fileName;
}
UnZipManager * UnZipManager::getInstance()
{
	if (_instance == nullptr) {
		_instance = new UnZipManager();
	}
	return _instance;
}

void UnZipManager::unZip(string zipPath, string unZipPath, string destPath, function<void(void)> unZipCompleteFunc, function<void(void)> unZipFailFunc)
{
	unZipStruct unZipData = { zipPath,unZipPath,destPath,unZipCompleteFunc,unZipFailFunc };
	updateUnZipList(unZipData);
	startUnCompress(unZipData);
}

bool UnZipManager::unCompress(unZipStruct data)
{
	string outFileName = data.zipPath;
	auto str = FileUtils::getInstance()->getSuitableFOpen(outFileName);
	auto zipfilePath = str.c_str();
	unzFile zipfile = unzOpen(zipfilePath);
	if (!zipfile)
	{
		CCLOG("can not open downloaded zip file %s\n", outFileName.c_str());
		return false;
	}

	// Get info about the zip file
	unz_global_info global_info;
	if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
	{
		CCLOG("can not read file global info of %s\n", outFileName.c_str());
		unzClose(zipfile);
		return false;
	}

	// Buffer to hold data read from the zip file
	char readBuffer[BUFFER_SIZE];
	// Loop to extract all files.
	uLong i;
	for (i = 0; i < global_info.number_entry; ++i)
	{
		// Get info about current file.
		unz_file_info fileInfo;
		char fileName[MAX_FILENAME];
		if (unzGetCurrentFileInfo(zipfile,
			&fileInfo,
			fileName,
			MAX_FILENAME,
			NULL,
			0,
			NULL,
			0) != UNZ_OK)
		{
			CCLOG("can not read compressed file info\n");
			unzClose(zipfile);
			return false;
		}

		const std::string fullPath = data.unzipPath + fileName;

		// Check if this entry is a directory or a file.
		const size_t filenameLength = strlen(fileName);
		if (fileName[filenameLength - 1] == '/')
		{
			//There are not directory entry in some case.
			//So we need to create directory when decompressing file entry
			if (!FileUtils::getInstance()->createDirectory(fullPath))
			{
				CCLOG("can not create directory %s\n", fullPath.c_str());
				unzClose(zipfile);
				return false;
			}
		}
		else
		{
			const string fileNameStr(fileName);
			
			size_t startIndex = 0;
			
			size_t index = fileNameStr.find("/", startIndex);

			while (index != string::npos)
			{
				const string dir = data.unzipPath + fileNameStr.substr(0, index);
				
				FILE *out = fopen(FileUtils::getInstance()->getSuitableFOpen(dir).c_str(), "r");

				if (!out) 
				{
					if (!FileUtils::getInstance()->createDirectory(dir))
					{
						CCLOG("can not create directory %s", dir.c_str());
						unzClose(zipfile);
						return false;
					}
					else 
					{
						CCLOG("create directory %s", dir.c_str());
					}
				}
				else
				{
					fclose(out);
				}

				startIndex = index + 1;

				index = fileNameStr.find("/", startIndex);
			}


			// Entry is a file, so extract it.

			// Open current file.
			if (unzOpenCurrentFile(zipfile) != UNZ_OK)
			{
				CCLOG("can not extract file %s\n", fileName);
				unzClose(zipfile);
				return false;
			}

			// Create a file to store current file.
			FILE *out = fopen(FileUtils::getInstance()->getSuitableFOpen(fullPath).c_str(), "wb");
			if (!out)
			{
				CCLOG("AssetsManagerEx : can not create decompress destination file %s (errno: %d)\n", fullPath.c_str(), errno);
				unzCloseCurrentFile(zipfile);
				unzClose(zipfile);
				return false;
			}

			// Write current file content to destinate file.
			int error = UNZ_OK;
			do
			{
				error = unzReadCurrentFile(zipfile, readBuffer, BUFFER_SIZE);
				if (error < 0)
				{
					CCLOG("can not read zip file %s, error code is %d\n", fileName, error);
					unzCloseCurrentFile(zipfile);
					unzClose(zipfile);
					return false;
				}

				if (error > 0)
				{
					fwrite(readBuffer, error, 1, out);
				}
			} while (error > 0);

			fclose(out);
		}

		unzCloseCurrentFile(zipfile);

		// Goto next entry listed in the zip file.
		if ((i + 1) < global_info.number_entry)
		{
			if (unzGoToNextFile(zipfile) != UNZ_OK)
			{
				CCLOG("can not read next file");
				unzClose(zipfile);
				return false;
			}
		}
	}


	unzClose(zipfile);

	return true;
}

void UnZipManager::startUnCompress(unZipStruct data)
{
	thread([this, data]()
	{
		do
		{
			auto zipState = getUnZipState(data.zipPath);
			if (zipState == UnZipState::UN_COMPRESS || zipState == UnZipState::COMPRESSING) {
				if (!unCompress(data)) {
					runCompressFailFunc(data);
					break;
				}else {
					FileUtils::getInstance()->removeFile(data.zipPath);
				}
			}else if (zipState == UnZipState::COMPRESS_END) {
				this->runCompressEndFunc(data);
			}
			string fullUnZipPath = data.unzipPath + getFileName(data.zipPath) + "/";
			bool ret = this->moveToDesPath(fullUnZipPath, data.destPath);
			if (ret) {
				removeDirectory(data.unzipPath);
				this->runCompressEndFunc(data);
			}
			else {
				runCompressFailFunc(data);
			}
			break;
		} while (0);
	}).detach();
}

UnZipState UnZipManager::getUnZipState(string zipPath)
{
	auto unZipData = getUnZipData(zipPath);
	bool isZipPathExit = FileUtils::getInstance()->isFileExist(unZipData.zipPath);
	bool isUnZipPathExit = FileUtils::getInstance()->isDirectoryExist(unZipData.unzipPath);
	bool isDesZipPathExit = FileUtils::getInstance()->isDirectoryExist(unZipData.destPath);
	if (isZipPathExit) {
		if (isUnZipPathExit) {
			return UnZipState::COMPRESSING;
		}
		else {
			return UnZipState::UN_COMPRESS;
		}
	}
	else if (isUnZipPathExit) {
		return UnZipState::COMPRESS_END;
	}
	else {
		return UnZipState::COPY_END;
	}
}

unZipStruct UnZipManager::getUnZipData(string path)
{
	for (auto iter = unZipList.begin(); iter != unZipList.end(); iter++) {
		if (iter->zipPath == path) {
			return *iter;
		}
	}
}

void UnZipManager::runCompressEndFunc(unZipStruct unZipData)
{
	Director::getInstance()->getScheduler()->performFunctionInCocosThread([unZipData, this] {
		unzipUnitListMutex.lock();
		removeFormUnZipList(unZipData);
		if (unZipData.unzipCompleteFunc) {
			unZipData.unzipCompleteFunc();
		}
		unzipUnitListMutex.unlock();
	});
}

void UnZipManager::runCompressFailFunc(unZipStruct unZipData)
{
	Director::getInstance()->getScheduler()->performFunctionInCocosThread([unZipData, this] {
		unzipUnitListMutex.lock();
		removeFormUnZipList(unZipData);
		if (unZipData.unzipFailFunc) {
			unZipData.unzipFailFunc();
		}
		unzipUnitListMutex.unlock();
	});
}

bool UnZipManager::moveToDesPath(string srcPath, string destPath)
{
	auto fileUtils = FileUtils::getInstance();
	vector<string> fileList;
	fileList.clear();
	fileUtils->listFilesRecursively(srcPath, &fileList);
	for (auto file : fileList) {
		auto relativePath = file.substr(srcPath.length(), string::npos);
		auto desFullPath = destPath + relativePath;
		if (desFullPath[desFullPath.length() - 1] == '/') {
			if (!fileUtils->isDirectoryExist(desFullPath)) {
				fileUtils->createDirectory(desFullPath);
			}
		}
		else {
			bool ret = fileUtils->renameFile(file, desFullPath);
			if (!ret) {
				return false;
			}
		}
	}
	return true;
}

void UnZipManager::removeDirectory(string path)
{
	auto fileUtils = FileUtils::getInstance();
	fileUtils->removeDirectory(path);
}



