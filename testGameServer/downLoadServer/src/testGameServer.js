var express = require("express");
var bodyParser = require("body-parser")
var app = express();
var config = require("./config/config");
var path = require("path");
class testGameServer{
    constructor(){
        this.Instance = null;
        app.all("*",function(req,res,next){
            res.header("Access-Control-Allow-Origon","*");
            res.header("Access-Control-Allow-Headers","Content-Type");
            res.header("Access-Control-Allow-Methods","*");
            res.header("Content-Type","application/json;charset=utf-8");
            next();
        });
        var staticPath = path.join(__dirname,"../downLoad");
        app.use(express.static(staticPath));
        app.use(bodyParser.json());
        app.post("/data",this.OnGetDataHander.bind(this));
        var server = app.listen(8000,function(){
            var host = server.address().address
            var port = server.address().port
            console.log("http://%s:%s",host,port)
        })
    }
    static getInstance(){
        if(!this.Instance)this.Instance = new testGameServer();
        return this.Instance;
    }
    OnGetDataHander(req,res){
        var data = req.body;
        try{
            var headStr = data.msgHead;
            var headData = data.msgData;
            this.router(headStr,headData,res);
        }catch(err){
            console.log(err);
        }
    }
    router(headStr,headData,res){
        if(!headStr)return;
        if(this[headStr+"Hander"])this[headStr+"Hander"].bind(this)(headData,res);
    }
    getZipVersionHander(headData,res){
        res.send(JSON.stringify(config.zipVersion));
    }
}
module.exports = testGameServer;
testGameServer.getInstance();
