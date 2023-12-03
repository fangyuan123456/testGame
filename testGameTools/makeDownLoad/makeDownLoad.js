const compressing = require("compressing");
let gamePathCfg = require("./../gamePathCfg");
let fs = require("fs");
let path = require("path");
var crypto = require("crypto");
let i = 2;
let isBaseFile = true;
let version = "1.0.0";
console.log(process.argv);
while(i<process.argv.length){
    var arg = process.argv[i];
    switch(arg){
        case "-b":
            isBaseFile = process.argv[i+1]=="y";
        break;
        case "-v":
            version = process.argv[i+1];
        break
    }
    i+=2;
};
console.log(isBaseFile);
console.log(version);
function checkAndCreateFolder(resPath){
    if(!fs.existsSync(resPath)){
        let dirPath = ""
        for(let i = resPath.length;i>0;i--){
            if(resPath.charAt(i) == "/"||resPath.charAt(i) == "\\"){
                dirPath = resPath.substring(0,i);
                break;
            }
        }
        if(!fs.existsSync(dirPath)){
            checkAndCreateFolder(dirPath)
        }
        fs.mkdirSync(resPath)
    }
}
function getAllDownLoadPath(){
    let fileMap = ["game"];
    let downLoadPath = gamePathCfg.gamePath+"res/downLoad/"
    let fileList = fs.readdirSync(downLoadPath);
    for(i in fileList){
        fileMap.push(fileList[i]);
    }
    return fileMap;
}
function copyFile(resPath,destPath,pathList,ignorePathList){
    var pathList = pathList || {};
    var ignorePathList = ignorePathList || {};
    var info = fs.statSync(resPath);
    if(info.isDirectory()){
        checkAndCreateFolder(destPath);
        let fileList = fs.readdirSync(resPath);
        for(let i = 0 ;i<fileList.length;i++){
            let newPath = path.join(resPath,fileList[i]);
            let isCopyPath = true;
            if(pathList.length>0){
                isCopyPath = false;
                if(pathList.indexOf(fileList[i])>-1){
                    isCopyPath = true;
                }
            }else if(ignorePathList.length>0){
                for(let j = 0;j<ignorePathList.length;j++){
                    if(newPath.indexOf(ignorePathList[j])>-1){
                        isCopyPath = false;
                        break;
                    }
                }
            }
            if(isCopyPath){
                let newDestPath = path.join(destPath,fileList[i]);
                copyFile(newPath,newDestPath,[],ignorePathList)
            }
        }
    }else{
        fs.copyFileSync(resPath,destPath);
    }
}
function rmGameDir(rmPath){
    let pathList = fs.readdirSync(rmPath);
    for(let i in pathList){
        let newPath = path.join(rmPath,pathList[i]);
        var info =fs.statSync(newPath);
        if(info.isDirectory()){
            rmGameDir(newPath)
        }else{
            fs.unlinkSync(newPath);
        }
    }
    fs.rmdirSync(rmPath);
}
function createAndCopyToBaseFolder(zipName){
    let resPath = "";
    let destPath = "";
    if(zipName == "game"){
        resPath = path.join(gamePathCfg.gamePath,"");
        destPath = path.join(__dirname+"/downLoadRes/","base/"+zipName+"/"+zipName+"_"+version);
    }else{
        resPath = path.join(gamePathCfg.gamePath,"res/downLoad/"+zipName);
        destPath = path.join(__dirname+"/downLoadRes/","base/"+zipName+"/"+zipName+"_"+version+"/res/downLoad/"+zipName);
    }
    let pathList = [];
    let ignorePathList = [];
    if(zipName == "game"){
        pathList = ["res","src"];
        ignorePathList = ["res\\downLoad"];
    }
    if(fs.existsSync(destPath)){
        rmGameDir(destPath);
    }
    copyFile(resPath,destPath,pathList,ignorePathList);
}
function checkVersion(nowVersion,lastVersion){
    let nowVersionList = nowVersion.split(".");
    let lastVersionList = lastVersion.split(".");
    for(let i = 0;i<nowVersionList;i++){
        if(nowVersionList[i]>lastVersionList[i]){
            return true;
        }
    }
    return false
}
function checkMd5(newFile,oldFile){
    var getFileMd5 = function(file){
        var md5 = null;
        if(fs.existsSync(file)){
            var fileData = fs.readFileSync(file);
            md5 = crypto.createHash("md5").update(fileData).digest("hex");
        }
        return md5;
    }
    return getFileMd5(newFile) != getFileMd5(oldFile);
}
function makeZipFile(zipName){
    var getBaseFolderName = function(){
        var baseFolderPath = path.join(__dirname+"/downLoadRes/","base/"+zipName);
        checkAndCreateFolder(baseFolderPath);
        var pathList = fs.readdirSync(baseFolderPath);
        var nearZipName = null;
        for(let i in pathList){
            let versionList = pathList[i].split("_");
            let versionStr = versionList[versionList.length-1]
            if(checkVersion(version,versionStr)){
                if(!nearZipName){
                    nearZipName = pathList[i];
                }else if(!checkVersion(pathList[i],nearZipName)){
                    nearZipName = pathList[i];
                }
            }
        }
        if(nearZipName){
            return path.join(__dirname+"/downLoadRes/","base/"+zipName+"/"+nearZipName);
        }
        console.error(zipName+" baseFolerName is not create");
    }
    var getZipList = function(){
        var baseFolderPath = path.join(__dirname+"/downLoadRes/","zip/"+zipName);
        checkAndCreateFolder(baseFolderPath);
        var pathList = fs.readdirSync(baseFolderPath);
        pathList.sort(function(a,b){
            let zipName1 = a.split(".zip")[0];
            let zipName2 = b.split(".zip")[0];
            let isOver = checkVersion(zipName1.split("_")[1],zipName2.split("_")[1]);
            if(isOver){
                return 1;
            }else{
                return -1;
            }
        })
        return pathList;
    }
    var unZipAndMove = function(zipPath,destPath,callFunc){
        var unZipFolder = zipPath.split(".zip")[0];
        checkAndCreateFolder(unZipFolder);
        var promiss = compressing.zip.uncompress(zipPath,unZipFolder);
        promiss.then(function(){
            copyFile(unZipFolder,destPath);
            rmGameDir(unZipFolder);
            callFunc();
        })
    }
    var baseFolderName = getBaseFolderName();
    var fullGamePath = path.join(__dirname+"/downLoadRes/","fullFolder/"+zipName);
    if(fs.existsSync(fullGamePath)){
        rmGameDir(fullGamePath);
    }
    copyFile(baseFolderName,fullGamePath);
    let zipList = getZipList();
    var unZipFunc = function(index){
        if(zipList[index]){
            unZipAndMove(path.join(__dirname+"/downLoadRes/","zip/"+zipName+"/"+zipList[index]),fullGamePath,function(){
                unZipFunc(++index);
            })
        }
    }
    unZipFunc(0);

    var checkMd5AndMakeZip = function(){
        checkMd5AndCopyFile = function(resPath,fullGamePath,destPath,checkFolderPathList,ignorePathList){
            for(var i = 0;i<checkFolderPathList.length;i++){
                var newResPath = path.join(resPath,checkFolderPathList[i]);
                var newFullPath = path.join(fullGamePath,checkFolderPathList[i]);
                var newDestPath = path.join(destPath,checkFolderPathList[i]);
                if(ignorePathList && ignorePathList.indexOf(newResPath)<0){
                    var info = fs.statSync(newResPath);
                    if(info.isDirectory()){
                        var pathList = fs.readdirSync(newResPath);
                        var newCheckList = [];
                        for(let j in pathList){
                            newCheckList.push(pathList[j]);
                        }
                        checkAndCreateFolder(newDestPath);
                        checkMd5AndCopyFile(newResPath,newFullPath,newDestPath,newCheckList,ignorePathList);
                    }else{
                        if(checkMd5(newResPath,newFullPath)){
                            fs.copyFileSync(newResPath,newDestPath);
                        }
                    }
                }
            }
        }
        var resPath = gamePathCfg.gamePath;
        var fullGamePath = path.join(__dirname+"/downLoadRes/","fullFolder/"+zipName);
        var destPath = path.join(__dirname+"/downLoadRes/","zip/"+zipName+"/"+zipName+"_"+version);
        var checkFolderPathList = null;
        var ignorePathList = null;
        if(zipName == "game"){
            checkFolderPathList = [
                "res","src"
            ]
            ignorePathList = [
                path.join(resPath,"res/downLoad")
            ];
        }else{
            checkFolderPathList = [
                "res/downLoad/"+zipName
            ]   
        }
        checkMd5AndCopyFile(resPath,fullGamePath,destPath,checkFolderPathList,ignorePathList);
        compressing.zip.compressing(destPath,destPath+".zip").then(()=>{
            rmGameDir(destPath)
        }).catch(err=>{
            console.log(err);
        });
    }
    checkMd5AndMakeZip();
}
function startRun(zipName){
    if(isBaseFile){
        createAndCopyToBaseFolder(zipName);
    }else{
        makeZipFile(zipName);
    }
}
function start(){
    let allDownLoadPath = getAllDownLoadPath();
    for(i in allDownLoadPath){
        startRun(allDownLoadPath[i]);
    }
}
start()