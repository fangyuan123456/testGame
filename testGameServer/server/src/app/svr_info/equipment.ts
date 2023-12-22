import { cmd } from "../../config/cmd";
import { gameLog } from "../common/logger";
import { E_itemT, RoleInfo } from "./roleInfo";
import { svr_info } from "./svr_info";

export class Equipment {
    private role: RoleInfo;
    public equip: I_equipment;
    private changedKey: { [key in keyof I_equipment]?: boolean } = {};
    private changed = false;
    constructor(role: RoleInfo, equip: I_equipment) {
        this.role = role;
        this.equip = equip;
    }


    updateSql() {
        if (!this.changed) {
            return;
        }
        this.changed = false;

        let updateArr: string[] = [];
        let key: keyof I_equipment;
        for (key in this.changedKey) {
            updateArr.push(key + "=" + this.equip[key]);
        }
        if (updateArr.length === 0) {
            return;
        }
        this.changedKey = {};
        let sql = `update equipment set ${updateArr.join(",")} where uid = ${this.role.uid} limit 1`;
        svr_info.mysql.query(sql, null, (err) => {
            err && gameLog.error(err);
        });
    }

    changeSqlKey(key: keyof I_equipment) {
        if (!this.changedKey[key]) {
            this.changedKey[key] = true;
            this.changed = true;
            this.role.addToSqlPool();
        }
    }

    onEquipChanged(msg: { "t": E_itemT, "id": number }) {
        this.role.getMsg(cmd.onEquipChanged, msg);
    }

    delEquip(t: E_itemT) {
        if (t === E_itemT.weapon) {
            this.equip.weapon = 0;
            this.role.equip.changeSqlKey("weapon");
        } else if (t === E_itemT.armor_physical) {
            this.equip.armor_physical = 0;
            this.role.equip.changeSqlKey("armor_physical");
        } else if (t === E_itemT.armor_magic) {
            this.equip.armor_magic = 0;
            this.role.equip.changeSqlKey("armor_magic");
        } else if (t === E_itemT.hp_add) {
            this.equip.hp_add = 0;
            this.role.equip.changeSqlKey("hp_add");
        } else if (t === E_itemT.mp_add) {
            this.equip.mp_add = 0;
            this.role.equip.changeSqlKey("mp_add");
        }
        this.onEquipChanged({ "t": t, "id": 0 })
    }
}


export interface I_equipment {
    "uid": number,              // uid
    "weapon": number,           // 武器
    "armor_physical": number,   // 物理护甲
    "armor_magic": number,      // 魔法抗性
    "hp_add": number,               // 加血量上限
    "mp_add": number,               // 加蓝量上限
}

