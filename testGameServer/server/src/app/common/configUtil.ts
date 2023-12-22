import * as path from "path";
import * as events from "events";
import * as fs from "fs";

interface I_cfgAll {
    "item": Dic<I_cfg_item>,
    "map": Dic<I_cfg_map>,
    "mapDoor": Dic<I_cfg_mapDoor>,
    "hero": Dic<I_cfg_hero>,
    "heroLv": Dic<Dic<I_cfg_heroLv>>,
    "skill": Dic<I_cfg_skill>,
    "shop": Dic<I_cfg_shop>,
    "shopItem": Dic<I_cfg_shopItem>,
    "monster": Dic<I_cfg_monster>,
    "mapMonster": Dic<I_cfg_mapMonster>,
    "mapId_monster": Dic<I_cfg_mapMonster[]>,
}


let jsonNames = {
    "item": true,
    "map": true,
    "mapDoor": true,
    "hero": true,
    "heroLv": true,
    "skill": true,
    "shop": true,
    "shopItem": true,
    "monster": true,
    "mapMonster": true,
};

let cfgAll: I_cfgAll = {} as any;
export let cfg_all = () => cfgAll;


let mapTileJsonDic: Dic<number[][]> = {};
export function getMapTileJson(mapId: number) {
    let data = mapTileJsonDic[mapId];
    if (data) {
        return data;
    }
    data = requireJson(("mapData/map" + mapId) as any);
    mapTileJsonDic[mapId] = data;
    return data;
}

// ************************************************************************************************************************
class EventProxy extends events.EventEmitter {
}

// 给逻辑代码用来监听配置改变（请注意，程序起名和策划表名可能不一样）
let eventProxy = new EventProxy();
export function cfg_on(cfgName: keyof I_cfgAll, cb: () => void) {
    eventProxy.on(cfgName, cb);
}
function cfg_emit(cfgName: keyof I_cfgAll) {
    eventProxy.emit(cfgName);
}

// json配置表的改变监听
let eventProxyJson = new EventProxy();
function jsonOn(jsonName: keyof typeof jsonNames, cb: () => void) {
    eventProxyJson.on(jsonName, cb);
}
function jsonEmit(jsonName: keyof typeof jsonNames) {
    eventProxyJson.emit(jsonName);
}

// 配置变化，延迟一定时间后统一通知外部
let changedNames: (keyof I_cfgAll)[] = [];
let timeout: NodeJS.Timeout = null as any;
function pushToChanged(cfgName: keyof I_cfgAll) {
    changedNames.push(cfgName);
    if (timeout) {
        return;
    }
    timeout = setTimeout(() => {
        timeout = null as any;
        let tmpNames = changedNames;
        changedNames = [];
        for (let one of tmpNames) {
            cfg_emit(one);
        }
    }, 10);
}

// ************************************************************************************************************************

//#region 配置表监听，并通知外部逻辑监听



jsonOn("item", () => {
    cfgAll.item = requireJson("item");
    pushToChanged("item");
});

jsonOn("map", () => {
    cfgAll.map = requireJson("map");
    pushToChanged("map");
});

jsonOn("mapDoor", () => {
    cfgAll.mapDoor = requireJson("mapDoor");
    pushToChanged("mapDoor");
});

jsonOn("hero", () => {
    cfgAll.hero = requireJson("hero");
    pushToChanged("hero");
});

jsonOn("heroLv", () => {
    let data = requireJson("heroLv");
    let endData: Dic<Dic<I_cfg_heroLv>> = {};
    for (let x in data) {
        let one = data[x];
        let heroOne = endData[one.heroId];
        if (!heroOne) {
            heroOne = {};
            endData[one.heroId] = heroOne;
        }
        heroOne[one.lv] = one;
    }
    cfgAll.heroLv = endData;
    pushToChanged("heroLv");
});

jsonOn("skill", () => {
    cfgAll.skill = requireJson("skill");
    pushToChanged("skill");
});

jsonOn("shop", () => {
    cfgAll.shop = requireJson("shop");
    pushToChanged("shop");
});

jsonOn("shopItem", () => {
    cfgAll.shopItem = requireJson("shopItem");
    pushToChanged("shopItem");
});

jsonOn("monster", () => {
    cfgAll.monster = requireJson("monster");
    pushToChanged("monster");
});

jsonOn("mapMonster", () => {
    cfgAll.mapMonster = requireJson("mapMonster");
    let obj: Dic<I_cfg_mapMonster[]> = {};
    for (let x in cfg_all().mapMonster) {
        let one = cfg_all().mapMonster[x];
        if (obj[one.mapId]) {
            obj[one.mapId].push(one);
        } else {
            obj[one.mapId] = [one];
        }
    }
    cfgAll.mapId_monster = obj;
    pushToChanged("mapMonster");
});


//#region 结构声明

/** 道具 */
interface I_cfg_item {
    id: number,
    type: number,
    num: number,
}

/** 地图信息 */
interface I_cfg_map {
    id: number,
    isCopy: number,
    copyNum: number,
}

/** 地图出口信息 */
export interface I_cfg_mapDoor {
    id: number,
    mapId: number,  // 地图id
    mapId2: number, // 目标地图id
    x: number,
    y: number,
    x2: number,
    y2: number,
}

/** 英雄 */
interface I_cfg_hero {
    id: number,
    initSkill: number,
    skill: number[],
    skillUnlockLv: number[],
}
/** 英雄升级数据 */
interface I_cfg_heroLv {
    "lv": number,
    "exp": number,
    "attack": number,
    "hp": number,
    "mp": number,
    "armor_p": number,
    "armor_m": number
}
/** 技能 */
interface I_cfg_skill {
    id: number,
    name: number,
    cd: number,     // 技能cd
    damage: number,  // 伤害值
    targetType: number, // 目标类型
    targetDistance: number, // 施法距离
    mpCost: number, // 魔法消耗
    range: number,  // 作用范围
}

/** 商店 */
interface I_cfg_shop {
    id: number, // 商店id
    mapId: number,  // 所在地图
    x: number,     // x
    y: number,  // y
}

/** 商店卖的物品 */
interface I_cfg_shopItem {
    id: number,
    shopId: number,
    itemId: number,
    gold: number,
}

/** 怪物数据 */
export interface I_cfg_monster {
    id: number,
    skill: number[],
    hp: number,
    mp: number,
    attack: number,
    armor_p: number,
    armor_m: number,
    items: number[][],
    exp: number,
    range: number,
}

/** 地图的怪物分布 */
interface I_cfg_mapMonster {
    id: number,
    mapId: number,
    monsterId: number,
    x: number,  // 初始坐标x
    y: number,  // 初始坐标y
    x2: number, // 巡逻坐标x
    y2: number, // 巡逻坐标y
}

//#endregion





interface Dic<T = any> {
    [id: string]: T
}

/** 加载数据 */
function requireJson(name: keyof typeof jsonNames) {
    let buf = fs.readFileSync(path.join(__dirname, "../../../jsonConfig/" + name + ".json"));
    return JSON.parse(buf.toString());
    // return require("../../../jsonConfig/" + name + ".json");
}
/** 删除不必要的缓存数据 */
function deleteCache(name: string) {
    // let module = require.cache[path.join(__dirname, "../../../jsonConfig/" + name + ".json")];
    // if (!module) {
    //     return;
    // }
    // delete require.cache[path.join(__dirname, "../../../jsonConfig/" + name + ".json")];
    // deleteModule([], require.main as any, module);
}

function deleteModule(checkedArr: NodeModule[], srcM: NodeModule, delM: NodeModule) {
    checkedArr.push(srcM);
    for (let i = srcM.children.length - 1; i >= 0; i--) {
        let one = srcM.children[i];
        if (one === delM) {
            srcM.children.splice(i, 1);
            break;
        } else if (checkedArr.includes(one)) {
            continue;
        } else {
            deleteModule(checkedArr, one, delM);
        }
    }
}


/**
 * 重新加载部分配置
 * @param jsonNameArr 配置表名字：以"/"分割
 */
export function cfgReload(jsonNameArr: string) {
    let jsonArr = jsonNameArr.split("/");
    let okArr: string[] = [];
    for (let one of jsonArr) {
        let str = one.trim();
        if (str === "") {
            continue;
        }
        if (jsonNames[str as keyof typeof jsonNames] !== undefined) {
            okArr.push(str);
        }
    }
    if (okArr.length === 0) {
        return;
    }
    for (let one of okArr) {
        deleteCache(one);
    }
    let key: keyof typeof jsonNames
    for (key in jsonNames) {
        jsonEmit(key);
    }
}

/**
 * 重新加载所有配置
 */
export function cfgReloadAll() {
    for (let one in jsonNames) {
        deleteCache(one);
    }
    let key: keyof typeof jsonNames
    for (key in jsonNames) {
        jsonEmit(key);
    }
}
