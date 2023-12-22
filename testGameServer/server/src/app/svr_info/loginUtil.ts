import { gameLog } from "../common/logger";
import { friendState, I_roleAllInfo } from "../common/someInterface";
import { getInsertSql, getInsertSqlArr } from "../util/mysql";
import { timeFormat, randStr } from "../util/util";
import { I_friendCache } from "./roleInfoMgr";
import { I_roleInfo, roleMysql } from "./roleInfo";
import { svr_info } from "./svr_info";
import { I_bagItem, I_item } from "./bag";
import { I_equipment } from "./equipment";


/**
 * 登录时的处理
 */
export class LoginUtil {
    constructor() {
    }

    getAllRoleInfo(uid: number, cb: (err: any, allInfo: I_roleAllInfo) => void) {
        this.getRoleInfo(uid, (err, role) => {
            if (err) {
                return cb(err, null as any);
            }
            this.getBag(uid, (err, items) => {
                if (err) {
                    return cb(err, null as any);
                }
                this.getEquip(uid, (err, equip) => {
                    if (err) {
                        return cb(err, null as any);
                    }
                    this.getFriends(uid, (err, friends) => {
                        if (err) {
                            return cb(err, null as any);
                        }
                        this.checkPublicMails(uid, (err) => {
                            if (err) {
                                return cb(err, null as any);
                            }
                            cb(null, { "role": role, "bag": items, "equip": equip });
                        });
                    });
                });
            });
        });
    }


    private getRoleInfo(uid: number, cb: (err: any, info: I_roleInfo) => void) {
        let sql = "select * from player where uid = ? limit 1";
        svr_info.mysql.query(sql, [uid], (err, res: I_roleInfo[]) => {
            if (err) {
                return cb(err, null as any);
            }
            if (res.length === 0) {
                return cb(new Error("role info not exists"), null as any);
            } else {
                let tmpRole = res[0];
                let key: keyof I_roleInfo;
                for (key in roleMysql) {
                    if (typeof roleMysql[key] === "object") {
                        (tmpRole as any)[key] = JSON.parse((tmpRole as any)[key]);
                    }
                }
                cb(null, tmpRole);
            }
        });
    }

    private getBag(uid: number, cb: (err: any, items: I_bagItem[]) => void) {
        let sql = "select * from bag where uid = ? limit 1";
        svr_info.mysql.query(sql, [uid], (err, res: { "items": string }[]) => {
            if (err) {
                return cb(err, null as any);
            }
            if (res.length !== 0) {
                return cb(null, JSON.parse(res[0].items));
            }
            let initItems: I_bagItem[] = [
                { "i": 0, "id": 1101, "num": 1 },
                { "i": 1, "id": 1102, "num": 2 },
                { "i": 2, "id": 1201, "num": 2 }
            ];
            let obj = {
                "uid": uid,
                "items": initItems
            }
            svr_info.mysql.query(getInsertSql("bag", obj), null, (err) => {
                if (err) {
                    return cb(err, null as any);
                }
                cb(null, initItems);
            });
        });

    }

    private getEquip(uid: number, cb: (err: any, equip: I_equipment) => void) {
        let sql = "select * from equipment where uid = ? limit 1";
        svr_info.mysql.query(sql, [uid], (err, res: I_equipment[]) => {
            if (err) {
                return cb(err, null as any);
            }
            if (res.length !== 0) {
                return cb(null, res[0]);
            }
            let initEquip: I_equipment = {
                "uid": uid,
                "weapon": 0,
                "armor_physical": 0,
                "armor_magic": 0,
                "hp_add": 1401,
                "mp_add": 0,
            }

            svr_info.mysql.query(getInsertSql("equipment", initEquip), null, (err) => {
                if (err) {
                    return cb(err, null as any);
                }
                cb(null, initEquip);
            });
        });

    }

    private getFriends(uid: number, cb: (err: any, friends: { "list": number[], "asklist": number[] }) => void) {
        return cb(null, { "list": [], "asklist": [] })
        let sql = "select uidF,state from friend where uid = ?";
        svr_info.mysql.query(sql, [uid], (err: any, res: { "uidF": number, "state": number }[]) => {
            if (err) {
                return cb(err, null as any);
            }
            let friends: { "list": number[], "asklist": number[] } = { "list": [], "asklist": [] };
            for (let one of res) {
                if (one.state === friendState.friend) {
                    friends.list.push(one.uidF);
                } else {
                    friends.asklist.push(one.uidF);
                }
            }
            cb(null, friends);
        });
    }

    /**
     * 从数据库中获取一些好友信息
     */
    getFriendInfoFromDb(uid: number, cb: (info: I_friendCache) => void) {
        let sql = "select nickname from player where uid = ? limit 1";
        svr_info.mysql.query(sql, [uid], function (err, res) {
            if (err) {
                gameLog.error(err);
                return cb(null as any);
            }
            if (res.length === 0) {
                return cb(null as any);
            }
            res = res[0];
            let info: I_friendCache = {
                "nickname": res["nickname"],
                "delTime": 0,
            }
            cb(info);
        });
    }

    // 检测全服邮件个人存储
    private checkPublicMails(uid: number, cb: (err: any) => void) {
        return cb(null);
        svr_info.mysql.query("select uid from mail_all where uid = ? limit 1", [uid], (err: any, res: any[]) => {
            if (err) {
                return cb(err);
            }
            if (res.length === 1) {
                return cb(null);
            }
            let str = JSON.stringify([]);
            svr_info.mysql.query("insert into mail_all(uid,readIds,getAwardIds,delIds,deadId) values(?,?,?,?,?)", [uid, str, str, str, 0], (err) => {
                if (err) {
                    return cb(err);
                }
                cb(null);
            });
        });
    }
}